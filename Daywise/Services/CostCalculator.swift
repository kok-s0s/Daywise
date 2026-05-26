import Foundation

enum CostCalculator {
    static func formatDailyCost(_ cost: Double) -> String {
        if cost < 0.01 {
            return "< ¥0.01/天"
        }
        return String(format: "¥%.2f/天", cost)
    }

    static func formatDays(_ days: Int) -> String {
        "已服役 \(days) 天"
    }
}
