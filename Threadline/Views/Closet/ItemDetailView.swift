import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let item: ClothingItem

    @State private var showArchiveConfirm = false
    @State private var showDeleteConfirm = false
    @State private var actionCompleted: String?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                itemPhoto
                statsRow
                wearHistory
                purchaseInfo
                actionsSection
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.xs)
            .padding(.bottom, Spacing.xl)
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if let action = actionCompleted {
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(ColorTokens.sage)
                    Text(action)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.ultraThinMaterial)
                .transition(.opacity)
            }
        }
        .sensoryFeedback(.success, trigger: actionCompleted ?? "")
        .confirmationDialog("Archive this item?", isPresented: $showArchiveConfirm, titleVisibility: .visible) {
            Button("Archive") {
                item.status = .archived
                showActionFeedback("Archived")
            }
            Button("Mark for Resale") {
                item.status = .forSale
                showActionFeedback("Marked for Sale")
            }
            Button("Donate") {
                item.status = .donated
                showActionFeedback("Marked as Donated")
            }
        } message: {
            Text("This item will be moved out of your active closet. You can restore it later.")
        }
        .confirmationDialog("Delete this item?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(item)
                dismiss()
            }
        } message: {
            Text("This permanently removes the item and all its wear history.")
        }
    }

    private func showActionFeedback(_ message: String) {
        withAnimation { actionCompleted = message }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { actionCompleted = nil }
            dismiss()
        }
    }

    // MARK: - Photo
    private var itemPhoto: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(ColorTokens.backgroundSecondary)
            .aspectRatio(4/3, contentMode: .fit)
            .overlay {
                if let data = item.photoData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: item.category.icon)
                            .font(.system(size: 36))
                        Text(item.category.displayName)
                            .font(.callout)
                    }
                    .foregroundStyle(ColorTokens.textTertiary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Stats
    private var statsRow: some View {
        HStack(spacing: 0) {
            statBadge(
                value: String(format: "$%.2f", item.costPerWear),
                label: "per wear",
                color: item.costPerWear < 10 ? ColorTokens.sage : ColorTokens.warning
            )
            Divider().frame(height: 36)
            statBadge(
                value: "\(item.totalWears)",
                label: "total wears",
                color: ColorTokens.warmIndigo
            )
            Divider().frame(height: 36)
            statBadge(
                value: daysSinceWornText,
                label: "last worn",
                color: item.isUnderperforming ? ColorTokens.warning : ColorTokens.textSecondary
            )
        }
        .padding(.vertical, Spacing.md)
        .background(ColorTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var daysSinceWornText: String {
        guard let days = item.daysSinceLastWorn else { return "Never" }
        if days == 0 { return "Today" }
        if days == 1 { return "Yesterday" }
        return "\(days)d ago"
    }

    private func statBadge(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.callout.monospaced().bold())
                .foregroundStyle(color)
            Text(label)
                .font(.footnote)
                .foregroundStyle(ColorTokens.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Wear History
    private var wearHistory: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Wear History")
                .font(.headline)

            let recentLogs = item.wearLogs
                .sorted { $0.date > $1.date }
                .prefix(10)

            if recentLogs.isEmpty {
                Text("No wear logs yet.")
                    .font(.callout)
                    .foregroundStyle(ColorTokens.textSecondary)
            } else {
                ForEach(Array(recentLogs), id: \.id) { log in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(ColorTokens.sage)
                            .font(.footnote)
                        Text(log.date, format: .dateTime.month(.abbreviated).day().year())
                            .font(.callout)
                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(ColorTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Purchase Info
    private var purchaseInfo: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Purchase Info")
                .font(.headline)
            infoRow("Purchased", value: item.purchaseDate.formatted(.dateTime.month(.abbreviated).day().year()))
            infoRow("Price", value: String(format: "$%.2f", item.purchasePrice))
            infoRow("Category", value: item.category.displayName)
            infoRow("Color", value: item.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(ColorTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(.callout)
            Spacer()
            Text(value).font(.callout).foregroundStyle(ColorTokens.textSecondary)
        }
    }

    // MARK: - Actions (functional)
    private var actionsSection: some View {
        VStack(spacing: Spacing.sm) {
            // Archive / Resale / Donate
            Button {
                showArchiveConfirm = true
            } label: {
                actionRow(icon: "archivebox", label: "Archive / Remove", color: ColorTokens.textSecondary)
            }
            .foregroundStyle(ColorTokens.textPrimary)

            Divider()

            // Delete permanently
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                actionRow(icon: "trash", label: "Delete Permanently", color: .red)
            }
        }
        .padding(Spacing.md)
        .background(ColorTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func actionRow(icon: String, label: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(label)
                .font(.body)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(ColorTokens.textTertiary)
        }
        .frame(minHeight: 44) // HIG: 44pt touch target
    }
}
