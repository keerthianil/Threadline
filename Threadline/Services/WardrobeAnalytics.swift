import Foundation

struct WardrobeAnalytics {
    let items: [ClothingItem]

    var activeItems: [ClothingItem] {
        items.filter { $0.status == .active }
    }

    var totalValue: Double {
        activeItems.reduce(0) { $0 + $1.purchasePrice }
    }

    var averageCostPerWear: Double {
        guard !activeItems.isEmpty else { return 0 }
        return activeItems.reduce(0) { $0 + $1.costPerWear } / Double(activeItems.count)
    }

    var utilizationPercentage: Double {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        let wornRecently = activeItems.filter { item in
            item.wearLogs.contains { $0.date >= thirtyDaysAgo }
        }
        guard !activeItems.isEmpty else { return 0 }
        return Double(wornRecently.count) / Double(activeItems.count)
    }

    var underperformers: [ClothingItem] {
        activeItems.filter { $0.isUnderperforming }
            .sorted { ($0.daysSinceLastWorn ?? 999) > ($1.daysSinceLastWorn ?? 999) }
    }

    var categoryBreakdown: [(category: ItemCategory, count: Int)] {
        let grouped = Dictionary(grouping: activeItems, by: \.category)
        return ItemCategory.allCases.map { cat in
            (category: cat, count: grouped[cat]?.count ?? 0)
        }.sorted { $0.count > $1.count }
    }

    var topPerformer: ClothingItem? {
        activeItems.filter { $0.totalWears > 0 }
            .min { $0.costPerWear < $1.costPerWear }
    }

    var monthlySpend: Double {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        return activeItems
            .filter { $0.purchaseDate >= thirtyDaysAgo }
            .reduce(0) { $0 + $1.purchasePrice }
    }
}
