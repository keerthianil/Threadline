import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [ClothingItem]
    @Query(sort: \WearLog.date, order: .reverse) private var recentLogs: [WearLog]
    private var items: [ClothingItem] {
        allItems.filter { $0.status == .active }
    }
    @State private var showQuickLog = false
    @State private var todayLogged = false
    @State private var showSuccessAlert = false
    @State private var showUnderperformers = false
    @State private var showPurchaseCheck = false

    private var streakDays: Int {
        var streak = 0
        let calendar = Calendar.current
        var checkDate = calendar.startOfDay(for: .now)
        let logDates = Set(recentLogs.map { calendar.startOfDay(for: $0.date) })

        if todayLogged {
            streak = 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        while logDates.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        return streak
    }

    private var topItem: ClothingItem? {
        items.max(by: { $0.totalWears < $1.totalWears })
    }

    private var leastWornItem: ClothingItem? {
        items.filter { $0.totalWears > 0 }.min(by: { $0.totalWears < $1.totalWears })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    if items.isEmpty {
                        emptyState
                    } else {
                        todayCard
                        quickLogPrompt
                        streakAndStatsRow
                        neglectedItemsButton
                        purchaseCheckButton
                        dailyInsight
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xl)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showQuickLog, onDismiss: {
                if todayLogged {
                    showSuccessAlert = true
                }
            }) {
                QuickLogView(didLog: $todayLogged)
                    .presentationDetents([.medium, .large])
            }
            .alert("Outfit Logged!", isPresented: $showSuccessAlert) {
                Button("OK") {
                    todayLogged = false
                }
            } message: {
                Text("Your wardrobe data just got smarter.")
            }
            .sensoryFeedback(.success, trigger: showSuccessAlert)
            .sheet(isPresented: $showUnderperformers) {
                NavigationStack {
                    UnderperformerListView(items: items.filter { $0.isUnderperforming })
                        .navigationTitle("Neglected Items")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showUnderperformers = false }
                            }
                        }
                }
            }
            .sheet(isPresented: $showPurchaseCheck) {
                PurchaseCheckView()
            }
            .onAppear {
                MockDataService.populateIfEmpty(context: modelContext)
            }
        }
    }

    // MARK: - Today Card
    private var todayCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.callout)
                .foregroundStyle(ColorTokens.textSecondary)
            Text("What are you wearing?")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Log Button (always visible)
    private var quickLogPrompt: some View {
        Button {
            showQuickLog = true
        } label: {
            HStack(spacing: Spacing.sm) {
                Text("Log Today's Outfit")
                    .font(.body.bold())
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(ColorTokens.warmIndigo)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Streak + Quick Stats
    private var streakAndStatsRow: some View {
        let totalValue = items.reduce(0) { $0 + $1.purchasePrice }
        let totalWears = items.reduce(0) { $0 + $1.totalWears }

        return HStack(spacing: Spacing.sm) {
            statCard(
                icon: "flame.fill",
                iconColor: streakDays > 0 ? .orange : ColorTokens.textTertiary,
                value: "\(streakDays)",
                label: "day streak"
            )
            statCard(value: "\(items.count)", label: "items")
            statCard(value: String(format: "$%.0f", totalValue), label: "value")
            statCard(value: "\(totalWears)", label: "wears")
        }
    }

    private func statCard(icon: String? = nil, iconColor: Color = ColorTokens.warmIndigo, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            if let icon {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                        .font(.callout)
                    Text(value)
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(ColorTokens.warmIndigo)
                }
            } else {
                Text(value)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(ColorTokens.warmIndigo)
            }
            Text(label)
                .font(.footnote)
                .foregroundStyle(ColorTokens.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
        .background(ColorTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Neglected Items
    private var neglectedItemsButton: some View {
        let count = items.filter { $0.isUnderperforming }.count

        return Button {
            showUnderperformers = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Label("Neglected items", systemImage: "exclamationmark.triangle")
                        .font(.headline)
                    Text(count == 0
                         ? "Everything is pulling its weight."
                         : "\(count) items not worn in 30+ days")
                        .font(.callout)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.callout)
                    .foregroundStyle(ColorTokens.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(ColorTokens.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase Check
    private var purchaseCheckButton: some View {
        Button {
            showPurchaseCheck = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Label("Should I buy this?", systemImage: "cart")
                        .font(.headline)
                    Text("Compare against what you already own.")
                        .font(.callout)
                        .foregroundStyle(ColorTokens.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.callout)
                    .foregroundStyle(ColorTokens.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(ColorTokens.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Daily Insight
    private var dailyInsight: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label("Insight", systemImage: "lightbulb")
                .font(.headline)
                .foregroundStyle(ColorTokens.warmIndigo)

            if let top = topItem {
                insightRow(
                    item: top,
                    title: "Most worn: **\(top.name)**",
                    subtitle: "\(top.totalWears) wears · \(String(format: "$%.2f", top.costPerWear)) per wear"
                )
            }

            if let least = leastWornItem, least.id != topItem?.id {
                insightRow(
                    item: least,
                    title: "Needs love: **\(least.name)**",
                    subtitle: "\(least.totalWears) wears · try wearing it this week"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(ColorTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func insightRow(item: ClothingItem, title: String, subtitle: String) -> some View {
        HStack(spacing: Spacing.sm) {
            RoundedRectangle(cornerRadius: 6)
                .fill(ColorTokens.backgroundTertiary)
                .frame(width: 44, height: 44)
                .overlay {
                    if let data = item.photoData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: item.category.icon)
                            .font(.footnote)
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(.init(title))
                    .font(.callout)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        EmptyStateView(
            icon: "tshirt",
            title: "Start with your 10 most-worn items",
            message: "Not your whole closet - just the ones you reach for.",
            actionTitle: "Add First Item",
            action: {}
        )
    }
}

// MARK: - Underperformer List
struct UnderperformerListView: View {
    let items: [ClothingItem]

    var body: some View {
        if items.isEmpty {
            ContentUnavailableView(
                "All caught up",
                systemImage: "checkmark.circle",
                description: Text("Everything has been worn recently.")
            )
        } else {
            List(items) { item in
                HStack(spacing: Spacing.sm) {
                    Image(systemName: item.category.icon)
                        .frame(width: 28)
                        .foregroundStyle(ColorTokens.warmIndigo)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name).font(.body)
                        if let days = item.daysSinceLastWorn {
                            Text("Last worn \(days) days ago")
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
            .listStyle(.plain)
        }
    }
}
