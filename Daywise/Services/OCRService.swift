import Vision
import UIKit

struct OCRService {
    struct OCRResult {
        var name: String?
        var price: Double?
    }

    func recognize(image: UIImage) async -> OCRResult {
        guard let cgImage = image.cgImage else { return OCRResult() }
        let texts: [String] = await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLanguages = ["zh-Hans", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
            return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        }.value
        return parseOCRText(texts)
    }

    // MARK: - Top-level parser

    private func parseOCRText(_ texts: [String]) -> OCRResult {
        OCRResult(
            name: extractProductName(from: texts),
            price: extractActualPayment(from: texts) ?? extractFallbackPrice(from: texts)
        )
    }

    // MARK: - Price: 实付款 priority path

    // 淘宝: "实付款" / 京东: "实付款"/"实付金额"/"应付总额" / 拼多多: "实付"/"需付款"
    private static let paymentKeywords = [
        "实付款", "实付金额", "应付总额", "应付款", "需付款",
        "实付",      // 拼多多短格式（放最后避免误匹配"实付款"里的"实付"）
    ]

    // 这些是折扣汇总说明，不是真实付款金额：共减¥2040 / 已优惠¥300 / 节省¥40
    // 淘宝：共减¥xxx 出现在 实付款 同行或紧邻行
    private static let discountSummaryRegexes: [String] = [
        #"共减[¥￥]\s*[\d,]+(?:\.\d{1,2})?"#,
        #"已优惠[¥￥]\s*[\d,]+(?:\.\d{1,2})?"#,
        #"节省[¥￥]\s*[\d,]+(?:\.\d{1,2})?"#,
        #"减免[¥￥]\s*[\d,]+(?:\.\d{1,2})?"#,
        #"省[¥￥]\s*[\d,]+(?:\.\d{1,2})?"#,
    ]

    private func extractActualPayment(from texts: [String]) -> Double? {
        for (i, text) in texts.enumerated() {
            guard Self.paymentKeywords.contains(where: { text.contains($0) }) else { continue }

            // 取 5 行窗口，覆盖淘宝把「实付款」「共减¥2040」「¥5959」分拆成三条 OCR 观测的情况
            let windowEnd = min(i + 5, texts.count)
            var combined = texts[i..<windowEnd].joined(separator: " ")

            // 删除所有折扣汇总金额，只留实际付款金额
            for pattern in Self.discountSummaryRegexes {
                combined = combined.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
            }

            // 取最后一个正数金额：付款金额在中文电商 UI 中始终排在折扣右侧/下方
            if let price = positiveAmounts(in: combined).last {
                return price
            }
        }
        return nil
    }

    // MARK: - Price: fallback（无实付款关键字时，例如商品详情页截图）

    // 这些行标签明确对应折扣而非付款，fallback 时跳过
    private static let discountLineKeywords = [
        "店铺优惠", "平台优惠", "支付优惠", "优惠券", "满减",
        "折扣", "红包", "津贴", "补贴", "运费险",
    ]

    private func extractFallbackPrice(from texts: [String]) -> Double? {
        for text in texts {
            let trimmed = text.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("-") { continue }
            if Self.discountLineKeywords.contains(where: { trimmed.contains($0) }) { continue }
            if let price = positiveAmounts(in: trimmed).first { return price }
        }
        return nil
    }

    // MARK: - Regex helpers

    /// 匹配正数 ¥ 金额，排除 -¥xxx（折扣行）
    private func positiveAmounts(in text: String) -> [Double] {
        guard let regex = try? NSRegularExpression(
            // 支持千分位：¥1,700 / ¥5,999  以及普通：¥5999 / ¥59.9
            pattern: #"(?<![−\-])[¥￥]\s*([\d,]+(?:\.\d{1,2})?)"#
        ) else { return [] }
        let nsRange = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: nsRange).compactMap { match in
            guard let r = Range(match.range(at: 1), in: text) else { return nil }
            // 去掉千分位逗号再转 Double
            return Double(text[r].replacingOccurrences(of: ",", with: ""))
        }
    }

    // MARK: - Name extraction

    private func extractProductName(from texts: [String]) -> String? {
        var candidates: [String] = []
        for text in texts {
            guard let cleaned = cleanedName(text) else { continue }
            candidates.append(cleaned)
            if candidates.count == 2 { break }
        }
        guard !candidates.isEmpty else { return nil }
        // OCR 可能把商品名拆成两行（如「苹果 iPhone 16」和「Pro」），尝试拼接
        if candidates.count == 2 {
            let joined = candidates.joined(separator: " ")
            if joined.count <= 55 { return joined }
        }
        return candidates.first
    }

    private func cleanedName(_ raw: String) -> String? {
        var text = raw.trimmingCharacters(in: .whitespaces)

        // 去除促销标签：【狂欢价】【限时特惠】【新品】等
        text = text.replacingOccurrences(
            of: #"【[^】]{1,15}】"#, with: "", options: .regularExpression
        ).trimmingCharacters(in: .whitespaces)

        // 处理「英文品牌/中文」格式，只在中文部分足够长时简化
        // Apple/苹果 iPhone 16 Pro → 苹果 iPhone 16 Pro（"苹果 iPhone 16 Pro" ≥ 4字）
        if let slash = text.range(of: "/"),
           isCJK(text[slash.upperBound...].first) {
            let after = String(text[slash.upperBound...])
            if after.count >= 4 { text = after }
        }
        text = text.trimmingCharacters(in: .whitespaces)

        guard text.count >= 3, text.count <= 55 else { return nil }
        guard !text.contains("¥"), !text.contains("￥") else { return nil }
        guard !text.contains("****"), !text.contains("小区") else { return nil }

        // 跳过纯数字行（订单号）
        let letters = text.unicodeScalars.filter { s in
            (s.value >= 0x4E00 && s.value <= 0x9FFF) ||
            (s.value >= 65 && s.value <= 90) ||
            (s.value >= 97 && s.value <= 122)
        }.count
        guard letters > 0,
              text.filter(\.isNumber).count < letters * 3 else { return nil }

        let uiTerms = [
            "交易成功", "查看发票", "商品总价", "店铺优惠", "平台优惠", "支付优惠",
            "实付款", "实付金额", "应付总额", "订单信息", "服务保障", "申请开票",
            "闲鱼转卖", "加入购物车", "申请售后", "大促价保", "极速退款",
            "无理由退换", "官方旗舰店", "客服", "更多", "复制", "分享",
            "天猫", "淘宝", "京东", "拼多多", "苏宁", "共减", "已优惠",
        ]
        guard !uiTerms.contains(where: { text.contains($0) }) else { return nil }

        return text
    }

    private func isCJK(_ char: Character?) -> Bool {
        char?.unicodeScalars.first.map { $0.value >= 0x4E00 && $0.value <= 0x9FFF } ?? false
    }
}
