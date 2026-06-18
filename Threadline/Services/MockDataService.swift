import Foundation
import SwiftData

struct MockDataService {
    static func populateIfEmpty(context: ModelContext) {
        let descriptor = FetchDescriptor<ClothingItem>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let items = createSampleItems()
        for item in items {
            context.insert(item)
        }

        addSampleWearLogs(items: items, context: context)
    }

    static func createSampleItems() -> [ClothingItem] {
        let calendar = Calendar.current

        return [
            ClothingItem(
                name: "Navy Wool Overcoat",
                category: .outerwear,
                purchasePrice: 275.00,
                purchaseDate: calendar.date(from: DateComponents(year: 2024, month: 11, day: 15))!,
                color: "Navy",
                seasons: [.fall, .winter]
            ),
            ClothingItem(
                name: "White Oxford Shirt",
                category: .tops,
                purchasePrice: 29.90,
                purchaseDate: calendar.date(from: DateComponents(year: 2025, month: 3, day: 8))!,
                color: "White",
                seasons: Season.allCases
            ),
            ClothingItem(
                name: "Black Slim Chinos",
                category: .bottoms,
                purchasePrice: 78.00,
                purchaseDate: calendar.date(from: DateComponents(year: 2025, month: 1, day: 20))!,
                color: "Black",
                seasons: Season.allCases
            ),
            ClothingItem(
                name: "Rust Linen Shirt",
                category: .tops,
                purchasePrice: 89.50,
                purchaseDate: calendar.date(from: DateComponents(year: 2025, month: 5, day: 2))!,
                color: "Rust",
                seasons: [.spring, .summer]
            ),
            ClothingItem(
                name: "Gray Crewneck Sweatshirt",
                category: .tops,
                purchasePrice: 135.00,
                purchaseDate: calendar.date(from: DateComponents(year: 2025, month: 2, day: 14))!,
                color: "Gray",
                seasons: [.fall, .winter, .spring]
            ),
            ClothingItem(
                name: "Olive Cargo Pants",
                category: .bottoms,
                purchasePrice: 128.00,
                purchaseDate: calendar.date(from: DateComponents(year: 2025, month: 4, day: 5))!,
                color: "Olive",
                seasons: Season.allCases
            ),
            ClothingItem(
                name: "White Leather Sneakers",
                category: .shoes,
                purchasePrice: 425.00,
                purchaseDate: calendar.date(from: DateComponents(year: 2024, month: 12, day: 1))!,
                color: "White",
                seasons: [.spring, .summer, .fall]
            ),
            ClothingItem(
                name: "Charcoal Suit Jacket",
                category: .outerwear,
                purchasePrice: 399.00,
                purchaseDate: calendar.date(from: DateComponents(year: 2024, month: 10, day: 18))!,
                color: "Charcoal",
                seasons: Season.allCases
            ),
            ClothingItem(
                name: "Striped Breton Top",
                category: .tops,
                purchasePrice: 90.00,
                purchaseDate: calendar.date(from: DateComponents(year: 2025, month: 6, day: 1))!,
                color: "Navy/White",
                seasons: [.spring, .summer]
            ),
            ClothingItem(
                name: "Black Chelsea Boots",
                category: .shoes,
                purchasePrice: 199.95,
                purchaseDate: calendar.date(from: DateComponents(year: 2024, month: 9, day: 10))!,
                color: "Black",
                seasons: [.fall, .winter, .spring]
            ),
        ]
    }

    static func addSampleWearLogs(items: [ClothingItem], context: ModelContext) {
        let calendar = Calendar.current
        let today = Date.now

        let wearCounts = [47, 31, 38, 3, 22, 8, 52, 6, 1, 63]

        for (index, item) in items.enumerated() {
            let count = wearCounts[index]
            for i in 0..<count {
                let daysAgo = Int.random(in: 1...(count > 10 ? 180 : 30))
                let wearDate = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
                let log = WearLog(date: wearDate, item: item)
                context.insert(log)
            }
        }
    }
}
