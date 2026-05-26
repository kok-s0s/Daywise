import Foundation

enum CostCalculator {
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

    private static func number(_ value: Double, decimals: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = decimals
        f.maximumFractionDigits = decimals
        return f.string(from: NSNumber(value: value)) ?? String(format: "%.\(decimals)f", value)
    }
}
