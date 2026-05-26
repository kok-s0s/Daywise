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

            return (request.results ?? []).compactMap {
                $0.topCandidates(1).first?.string
            }
        }.value

        return parseOCRText(texts)
    }

    // MARK: - Parsing

    private func parseOCRText(_ texts: [String]) -> OCRResult {
        OCRResult(
            name: extractProductName(from: texts),
            price: extractActualPayment(from: texts) ?? extractFirstPositivePrice(from: texts)
        )
    }

    // MARK: - Price

    /// 优先识别「实付款」行，取该行最后一个正数金额（跳过优惠金额）
    private func extractActualPayment(from texts: [String]) -> Double? {
        let keywords = ["实付款", "实付", "应付款", "应付总额"]
        for (i, text) in texts.enumerated() {
            guard keywords.contains(where: { text.contains($0) }) else { continue }
            if let price = positivePrices(in: text).last { return price }
            if i + 1 < texts.count, let price = positivePrices(in: texts[i + 1]).first {
                return price
            }
        }
        return nil
    }

    private func extractFirstPositivePrice(from texts: [String]) -> Double? {
        texts.lazy.compactMap { positivePrices(in: $0).first }.first
    }

    /// 匹配正数金额，排除 -¥1700 这类折扣行
    private func positivePrices(in text: String) -> [Double] {
        guard let regex = try? NSRegularExpression(
            pattern: #"(?<![−\-])[¥￥]\s*(\d+(?:\.\d{1,2})?)"#
        ) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let r = Range(match.range(at: 1), in: text) else { return nil }
            return Double(text[r])
        }
    }

    // MARK: - Name

    private func extractProductName(from texts: [String]) -> String? {
        var candidates: [String] = []
        for text in texts {
            guard let cleaned = cleanedProductName(text) else { continue }
            candidates.append(cleaned)
            if candidates.count == 2 { break }
        }
        guard !candidates.isEmpty else { return nil }

        // 两段短候选拼成完整名称（处理 OCR 把商品名拆成两行的情况）
        if candidates.count == 2 {
            let joined = candidates.joined(separator: " ")
            if joined.count <= 55 { return joined }
        }
        return candidates.first
    }

    private func cleanedProductName(_ raw: String) -> String? {
        var text = raw.trimmingCharacters(in: .whitespaces)

        // 去掉促销标签：【狂欢价】【限时特惠】等（最多12字以内）
        text = text.replacingOccurrences(
            of: #"【[^】]{1,12}】"#, with: "", options: .regularExpression
        ).trimmingCharacters(in: .whitespaces)

        // 处理「英文/中文」格式（如 Apple/苹果 iPhone 16 Pro）
        // 只有中文部分足够长时才做简化，避免把短品牌名截断
        if let slashRange = text.range(of: "/"),
           isCJK(text[slashRange.upperBound...].first) {
            let chinesePart = String(text[slashRange.upperBound...])
            if chinesePart.count >= 4 {
                text = chinesePart
            }
        }
        text = text.trimmingCharacters(in: .whitespaces)

        // 长度过滤
        guard text.count >= 3, text.count <= 55 else { return nil }

        // 跳过含价格符号的行
        guard !text.contains("¥"), !text.contains("￥") else { return nil }

        // 跳过地址/电话行
        guard !text.contains("****"), !text.contains("小区"), !text.contains("省") || text.count < 10 else { return nil }

        // 跳过纯数字行（订单号等，如 4397740020190731827）
        let digitCount = text.filter(\.isNumber).count
        let charCount = text.unicodeScalars.filter { s in
            (s.value >= 0x4E00 && s.value <= 0x9FFF) ||
            (s.value >= 65 && s.value <= 90) ||
            (s.value >= 97 && s.value <= 122)
        }.count
        guard charCount > 0, digitCount < charCount * 3 else { return nil }

        // 跳过常见 UI 文案
        let uiTerms = [
            "交易成功", "查看发票", "商品总价", "店铺优惠", "平台优惠", "支付优惠",
            "实付款", "订单信息", "服务保障", "申请开票", "闲鱼转卖", "加入购物车",
            "申请售后", "大促价保", "极速退款", "无理由退换", "官方旗舰店",
            "客服", "更多", "复制", "分享", "收藏", "天猫", "淘宝",
            "京东", "拼多多", "苏宁", "唯品会", "共减", "已优惠"
        ]
        guard !uiTerms.contains(where: { text.contains($0) }) else { return nil }

        return text
    }

    private func isCJK(_ char: Character?) -> Bool {
        char?.unicodeScalars.first.map { $0.value >= 0x4E00 && $0.value <= 0x9FFF } ?? false
    }
}
