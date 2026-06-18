import SwiftUI
import SwiftData

struct QuickLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allItems: [ClothingItem]
    private var items: [ClothingItem] {
        allItems.filter { $0.status == .active }
    }
    @Binding var didLog: Bool
    @State private var selectedItems: Set<UUID> = []

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.sm) {
                Text("Tap what you're wearing")
                    .font(.callout)
                    .foregroundStyle(ColorTokens.textSecondary)

                if !selectedItems.isEmpty {
                    Text("\(selectedItems.count) selected")
                        .font(.callout.bold())
                        .foregroundStyle(ColorTokens.warmIndigo)
                }

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(items) { item in
                            quickLogTile(item)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
            }
            .padding(.top, Spacing.sm)
            .navigationTitle("Log Outfit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        logSelectedItems()
                        didLog = true
                        dismiss()
                    }
                    .bold()
                    .disabled(selectedItems.isEmpty)
                }
            }
        }
    }

    private func quickLogTile(_ item: ClothingItem) -> some View {
        let isSelected = selectedItems.contains(item.id)

        return Button {
            withAnimation(.spring(response: 0.15)) {
                if isSelected {
                    selectedItems.remove(item.id)
                } else {
                    selectedItems.insert(item.id)
                }
            }
        } label: {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(ColorTokens.backgroundSecondary)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        if let data = item.photoData,
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: item.category.icon)
                                .font(.callout)
                                .foregroundStyle(ColorTokens.textTertiary)
                        }
                    }
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(ColorTokens.warmIndigo, lineWidth: 3)
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(ColorTokens.warmIndigo)
                                .background(Circle().fill(.white))
                                .offset(x: 20, y: -20)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(item.name)
                    .font(.footnote)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(ColorTokens.textPrimary)
            }
        }
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    private func logSelectedItems() {
        for item in items where selectedItems.contains(item.id) {
            let log = WearLog(date: .now, item: item)
            modelContext.insert(log)
        }
    }
}
