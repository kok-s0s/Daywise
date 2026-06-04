import Foundation
import SwiftData

enum ItemStatus: String, Codable, CaseIterable {
    case serving
    case retired
    case sold

    var displayName: String {
        switch self {
        case .serving: return "服役中"
        case .retired: return "已退役"
        case .sold: return "已出售"
        }
    }
}

enum ValueVerdict: String {
    case excellent = "超值"
    case good = "正常"
    case expensive = "偏贵"
    case impulse = "冲动消费"
    case paidBack = "已经回本"

    var message: String {
        switch self {
        case .excellent: return "使用足够充分，成本正在快速摊薄。"
        case .good: return "成本表现健康，继续使用会更划算。"
        case .expensive: return "当前单次成本偏高，建议提高使用频率。"
        case .impulse: return "使用次数太少，可能是一次冲动消费。"
        case .paidBack: return "单次成本已经很低，这笔消费基本值回来了。"
        }
    }
}

@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var name: String
    var price: Double
    var purchaseDate: Date
    var category: String
    var statusRaw: String
    var soldPrice: Double?
    var soldDate: Date?
    var imageData: Data?
    var note: String?
    var createdAt: Date
    var useCount: Int?
    var lastUsedAt: Date?
    var satisfactionScore: Int?

    init(
        name: String,
        price: Double,
        purchaseDate: Date,
        category: String = "其他",
        status: ItemStatus = .serving,
        soldPrice: Double? = nil,
        soldDate: Date? = nil,
        imageData: Data? = nil,
        note: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.price = price
        self.purchaseDate = purchaseDate
        self.category = category
        self.statusRaw = status.rawValue
        self.soldPrice = soldPrice
        self.soldDate = soldDate
        self.imageData = imageData
        self.note = note
        self.createdAt = Date()
        self.useCount = nil
        self.lastUsedAt = nil
        self.satisfactionScore = nil
    }

    var status: ItemStatus {
        get { ItemStatus(rawValue: statusRaw) ?? .serving }
        set { statusRaw = newValue.rawValue }
    }

    var daysInService: Int {
        let end = soldDate ?? Date()
        let days = Calendar.current.dateComponents([.day], from: purchaseDate, to: end).day ?? 0
        return max(1, days)
    }

    var dailyCost: Double {
        if status == .sold, let soldPrice {
            return max(0, price - soldPrice) / Double(daysInService)
        }
        return price / Double(daysInService)
    }

    var displayStatus: String { status.displayName }

    var effectiveUseCount: Int {
        max(0, useCount ?? 0)
    }

    var isUsageTracked: Bool {
        useCount != nil
    }

    var costPerUse: Double? {
        guard effectiveUseCount > 0 else { return nil }
        if status == .sold, let soldPrice {
            return max(0, price - soldPrice) / Double(effectiveUseCount)
        }
        return price / Double(effectiveUseCount)
    }

    var daysSinceLastUse: Int? {
        guard let lastUsedAt else { return nil }
        let days = Calendar.current.dateComponents([.day], from: lastUsedAt, to: Date()).day ?? 0
        return max(0, days)
    }

    var valueVerdict: ValueVerdict {
        if let costPerUse, costPerUse <= 5, daysInService >= 60 {
            return .paidBack
        }
        if let costPerUse {
            if costPerUse <= 10 { return .excellent }
            if costPerUse <= 50 { return .good }
            if effectiveUseCount <= 3 && daysInService >= 30 { return .impulse }
            return .expensive
        }
        if isUsageTracked, effectiveUseCount == 0, daysInService >= 14 {
            return .impulse
        }
        if dailyCost <= 1 { return .excellent }
        if dailyCost <= 10 { return .good }
        return .expensive
    }

    func markUsed(on date: Date = Date()) {
        useCount = effectiveUseCount + 1
        lastUsedAt = date
    }

    func unmarkUsed() {
        guard isUsageTracked, effectiveUseCount > 0 else { return }
        useCount = effectiveUseCount - 1
        if effectiveUseCount == 0 {
            lastUsedAt = nil
        }
    }

    func setUseCount(_ count: Int) {
        let normalized = max(0, count)
        useCount = normalized
        lastUsedAt = normalized > 0 ? (lastUsedAt ?? Date()) : nil
    }
}
