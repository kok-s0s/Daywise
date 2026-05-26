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
}
