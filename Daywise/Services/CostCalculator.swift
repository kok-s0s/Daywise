import Foundation

enum CostCalculator {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "zh_CN")
        return f
    }()

    static func formatDailyCost(_ cost: Double) -> String {
        if cost < 0.01 { return "< ¥0.01/天" }
        return "¥\(number(cost, decimals: 2))/天"
    }

    static func formatDays(_ days: Int) -> String {
        "已服役 \(days) 天"
    }

    // Thousand-separated price, e.g. ¥1,234 or ¥1,234.56
    static func formatPrice(_ price: Double, decimals: Int = 0) -> String {
        "¥\(number(price, decimals: decimals))"
    }

    static func formatCostPerUse(_ cost: Double?) -> String {
        guard let cost else { return "未记录使用" }
        if cost < 0.01 { return "< ¥0.01/次" }
        return "¥\(number(cost, decimals: 2))/次"
    }

    static func parseAmount(_ text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "￥", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "，", with: "")
            .replacingOccurrences(of: "。", with: ".")

        guard !normalized.isEmpty else { return nil }
        return Double(normalized)
    }

    private static func number(_ value: Double, decimals: Int) -> String {
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(decimals)f", value)
    }
}
