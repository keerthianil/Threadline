import Foundation
import SwiftData

@Model
final class ClothingItem {
    var id: UUID
    var name: String
    var category: ItemCategory
    var purchasePrice: Double
    var purchaseDate: Date
    var photoData: Data?
    var color: String
    var seasons: [Season]
    var status: ItemStatus

    @Relationship(deleteRule: .cascade, inverse: \WearLog.item)
    var wearLogs: [WearLog]

    var costPerWear: Double {
        guard !wearLogs.isEmpty else { return purchasePrice }
        return purchasePrice / Double(wearLogs.count)
    }

    var totalWears: Int {
        wearLogs.count
    }

    var lastWornDate: Date? {
        wearLogs.sorted { $0.date > $1.date }.first?.date
    }

    var daysSinceLastWorn: Int? {
        guard let lastWorn = lastWornDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastWorn, to: .now).day
    }

    var isUnderperforming: Bool {
        guard let days = daysSinceLastWorn else { return totalWears == 0 }
        return days > 30
    }

    init(
        name: String,
        category: ItemCategory,
        purchasePrice: Double,
        purchaseDate: Date = .now,
        photoData: Data? = nil,
        color: String = "",
        seasons: [Season] = Season.allCases,
        status: ItemStatus = .active
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.purchasePrice = purchasePrice
        self.purchaseDate = purchaseDate
        self.photoData = photoData
        self.color = color
        self.seasons = seasons
        self.status = status
        self.wearLogs = []
    }
}

enum ItemCategory: String, Codable, CaseIterable, Identifiable {
    case tops, bottoms, outerwear, shoes, accessories, dresses
    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .tops: "tshirt"
        case .bottoms: "figure.walk"
        case .outerwear: "cloud.snow"
        case .shoes: "shoeprints.fill"
        case .accessories: "watch"
        case .dresses: "figure.dress.line.vertical.figure"
        }
    }
}

enum Season: String, Codable, CaseIterable {
    case spring, summer, fall, winter
}

enum ItemStatus: String, Codable, CaseIterable {
    case active, stored, archived, donated, forSale

    var displayName: String {
        switch self {
        case .active: "Active"
        case .stored: "Stored"
        case .archived: "Archived"
        case .donated: "Donated"
        case .forSale: "For Sale"
        }
    }
}
