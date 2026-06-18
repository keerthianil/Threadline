import Foundation

struct HealthScore {
    let utilization: Double
    let avgCostPerWear: Double
    let categoryBalance: Double
    let overall: Int

    static func calculate(items: [ClothingItem]) -> HealthScore {
        let activeItems = items.filter { $0.status == .active }
        guard !activeItems.isEmpty else {
            return HealthScore(utilization: 0, avgCostPerWear: 0, categoryBalance: 0, overall: 0)
        }

        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        let wornRecently = activeItems.filter { item in
            item.wearLogs.contains { $0.date >= thirtyDaysAgo }
        }
        let utilization = Double(wornRecently.count) / Double(activeItems.count)

        let totalCPW = activeItems.reduce(0.0) { $0 + $1.costPerWear }
        let avgCPW = totalCPW / Double(activeItems.count)
        let cpwScore = min(1.0, max(0, 1.0 - (avgCPW / 50.0)))

        let categoryCounts = Dictionary(grouping: activeItems, by: \.category)
        let idealPerCategory = Double(activeItems.count) / Double(ItemCategory.allCases.count)
        let categoryVariance = categoryCounts.values.reduce(0.0) { sum, items in
            sum + abs(Double(items.count) - idealPerCategory)
        }
        let maxVariance = Double(activeItems.count)
        let categoryBalance = max(0, 1.0 - (categoryVariance / maxVariance))

        let overall = Int((utilization * 40 + cpwScore * 35 + categoryBalance * 25))

        return HealthScore(
            utilization: utilization,
            avgCostPerWear: avgCPW,
            categoryBalance: categoryBalance,
            overall: min(100, max(0, overall))
        )
    }
}
