import SwiftUI
import SwiftData
import Charts

struct InsightsDashboardView: View {
    @Query private var items: [ClothingItem]
    @AppStorage("utilizationTarget") private var utilizationTarget: Double = 70

    private var activeItems: [ClothingItem] {
        items.filter { $0.status == .active }
    }

    private var analytics: WardrobeAnalytics {
        WardrobeAnalytics(items: activeItems)
    }

    private var healthScore: HealthScore {
        HealthScore.calculate(items: activeItems)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if activeItems.isEmpty {
                    EmptyStateView(
                        icon: "chart.bar",
                        title: "No data yet",
                        message: "Add items and start logging outfits to unlock insights.",
                        actionTitle: nil,
                        action: {}
                    )
                    .padding(.top, Spacing.xxl)
                } else if activeItems.count < 5 {
                    lockedInsights
                } else {
                    VStack(spacing: Spacing.md) {
                        healthScoreCard
                        utilizationCard
                        spendingCard
                        categoryChart
                        topPerformersSection
                        underperformersSection

                        Text("All insights based on purchase prices you entered.")
                            .font(.footnote)
                            .foregroundStyle(ColorTokens.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.xs)
                    .padding(.bottom, Spacing.xl)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Locked State
    private var lockedInsights: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "lock")
                .font(.system(size: 36))
                .foregroundStyle(ColorTokens.textTertiary)
            Text("Insights unlock with 5+ items")
                .font(.headline)
            Text("You have \(activeItems.count). Add \(5 - activeItems.count) more to get started.")
                .font(.callout)
                .foregroundStyle(ColorTokens.textSecondary)
        }
        .padding(.top, Spacing.xxl)
    }

    // MARK: - Health Score
    private var healthScoreCard: some View {
        HStack(spacing: Spacing.lg) {
            HealthScoreRing(score: healthScore.overall, size: 90)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Wardrobe Health")
                    .font(.headline)
                Text(healthScoreLabel)
                    .font(.callout)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(ColorTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var healthScoreLabel: String {
        switch healthScore.overall {
        case 80...100: return "Excellent — your wardrobe is working hard."
        case 60..<80: return "Good — a few items need attention."
        case 40..<60: return "Fair — time to review what's sitting idle."
        default: return "Needs work — lots of underperformers."
        }
    }

    // MARK: - Utilization
    private var utilizationCard: some View {
        let pct = analytics.utilizationPercentage
        let target = utilizationTarget / 100.0
        let wornCount = Int(pct * Double(activeItems.count))
        let meetsTarget = pct >= target

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Utilization")
                    .font(.headline)
                Spacer()
                Text("\(Int(pct * 100))%")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(meetsTarget ? ColorTokens.sage : ColorTokens.warning)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ColorTokens.backgroundTertiary)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(meetsTarget ? ColorTokens.sage : ColorTokens.warning)
                        .frame(width: geo.size.width * min(pct, 1.0), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(wornCount) of \(activeItems.count) items worn this month")
                    .font(.callout)
                    .foregroundStyle(ColorTokens.textSecondary)
                Spacer()
                Text("Goal: \(Int(utilizationTarget))%")
                    .font(.footnote)
                    .foregroundStyle(meetsTarget ? ColorTokens.sage : ColorTokens.textTertiary)
            }
        }
        .padding(Spacing.md)
        .background(ColorTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Spending
    private var spendingCard: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Avg Cost-Per-Wear")
                    .font(.headline)
                Text(String(format: "$%.2f", analytics.averageCostPerWear))
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(analytics.averageCostPerWear < 10 ? ColorTokens.sage : ColorTokens.warmIndigo)
                Text(analytics.averageCostPerWear < 5 ? "Great value from your wardrobe." : analytics.averageCostPerWear < 15 ? "Room to improve — wear items more." : "High — some items aren't earning their keep.")
                    .font(.callout)
                    .foregroundStyle(ColorTokens.textSecondary)
            }

            Spacer()

            VStack(spacing: Spacing.xs) {
                Text(String(format: "$%.0f", analytics.monthlySpend))
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(ColorTokens.warmIndigo)
                Text("spent\nthis month")
                    .font(.footnote)
                    .foregroundStyle(ColorTokens.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.md)
        .background(ColorTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Category Chart
    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Category Balance")
                .font(.headline)

            Chart(analytics.categoryBreakdown, id: \.category) { item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Category", item.category.displayName)
                )
                .foregroundStyle(ColorTokens.warmIndigo.gradient)
                .cornerRadius(4)
                .annotation(position: .trailing, spacing: 4) {
                    Text("\(item.count)")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.callout)
                }
            }
            .chartXAxis(.hidden)
            .frame(height: CGFloat(analytics.categoryBreakdown.count) * 40)
        }
        .padding(Spacing.md)
        .background(ColorTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Top Performers
    private var topPerformersSection: some View {
        let topItems = activeItems
            .filter { $0.totalWears > 0 }
            .sorted { $0.costPerWear < $1.costPerWear }
            .prefix(3)

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Best Value Items")
                    .font(.headline)
                Spacer()
                Image(systemName: "trophy")
                    .foregroundStyle(ColorTokens.sage)
            }

            if topItems.isEmpty {
                Text("Start logging outfits to see your best performers.")
                    .font(.callout)
                    .foregroundStyle(ColorTokens.textSecondary)
            } else {
                ForEach(Array(topItems.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: Spacing.sm) {
                        Text("\(index + 1)")
                            .font(.callout.bold().monospacedDigit())
                            .foregroundStyle(ColorTokens.warmIndigo)
                            .frame(width: 20)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(ColorTokens.backgroundTertiary)
                            .frame(width: 36, height: 36)
                            .overlay {
                                if let data = item.photoData,
                                   let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Image(systemName: item.category.icon)
                                        .font(.caption)
                                        .foregroundStyle(ColorTokens.textTertiary)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.name)
                                .font(.body)
                            Text("\(item.totalWears) wears")
                                .font(.footnote)
                                .foregroundStyle(ColorTokens.textSecondary)
                        }

                        Spacer()

                        Text(String(format: "$%.2f", item.costPerWear))
                            .font(.callout.bold().monospacedDigit())
                            .foregroundStyle(ColorTokens.sage)
                    }
                    if index < topItems.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(ColorTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Underperformers
    private var underperformersSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Underperformers")
                    .font(.headline)
                Spacer()
                Text("\(analytics.underperformers.count) items")
                    .font(.footnote)
                    .foregroundStyle(ColorTokens.textSecondary)
            }

            if analytics.underperformers.isEmpty {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ColorTokens.sage)
                    Text("Everything in your closet is pulling its weight.")
                        .font(.callout)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
            } else {
                ForEach(analytics.underperformers.prefix(5)) { item in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(ColorTokens.warning)
                            .font(.footnote)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(ColorTokens.backgroundTertiary)
                            .frame(width: 36, height: 36)
                            .overlay {
                                if let data = item.photoData,
                                   let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                } else {
                                    Image(systemName: item.category.icon)
                                        .font(.caption)
                                        .foregroundStyle(ColorTokens.textTertiary)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        Text(item.name)
                            .font(.body)
                        Spacer()
                        if let days = item.daysSinceLastWorn {
                            Text("\(days)d ago")
                                .font(.footnote)
                                .foregroundStyle(ColorTokens.textSecondary)
                        } else {
                            Text("Never worn")
                                .font(.footnote)
                                .foregroundStyle(ColorTokens.warning)
                        }
                    }
                }
            }
        }
        .padding(Spacing.md)
        .background(ColorTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
