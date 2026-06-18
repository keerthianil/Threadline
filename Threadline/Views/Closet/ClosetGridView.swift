import SwiftUI
import SwiftData

enum ClosetSortOption: String, CaseIterable, Identifiable {
    case name = "Name"
    case priceLowToHigh = "Price: Low → High"
    case priceHighToLow = "Price: High → Low"
    case mostWorn = "Most Worn"
    case leastWorn = "Least Worn"
    case recentlyAdded = "Recently Added"
    case color = "Color"

    var id: String { rawValue }
}

struct ClosetGridView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClothingItem.name) private var allItems: [ClothingItem]
    @State private var selectedCategory: ItemCategory?
    @State private var showAddItem = false
    @State private var searchText = ""
    @State private var sortOption: ClosetSortOption = .name
    @State private var isSelecting = false
    @State private var selectedItems: Set<UUID> = []
    @State private var showDeleteConfirm = false
    @State private var showArchivedItems = false

    private var activeItems: [ClothingItem] {
        allItems.filter { $0.status == .active }
    }

    private var filteredItems: [ClothingItem] {
        var result = activeItems
        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        switch sortOption {
        case .name:
            result.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .priceLowToHigh:
            result.sort { $0.purchasePrice < $1.purchasePrice }
        case .priceHighToLow:
            result.sort { $0.purchasePrice > $1.purchasePrice }
        case .mostWorn:
            result.sort { $0.totalWears > $1.totalWears }
        case .leastWorn:
            result.sort { $0.totalWears < $1.totalWears }
        case .recentlyAdded:
            result.sort { $0.purchaseDate > $1.purchaseDate }
        case .color:
            result.sort { $0.color.localizedCompare($1.color) == .orderedAscending }
        }
        return result
    }

    private var archivedItems: [ClothingItem] {
        allItems.filter { $0.status != .active }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.sm) {
                    filterBar
                    sortAndCountBar

                    if filteredItems.isEmpty {
                        if activeItems.isEmpty {
                            EmptyStateView(
                                icon: "rectangle.grid.2x2",
                                title: "Your closet is empty",
                                message: "Start with your 10 most-worn items.",
                                actionTitle: "Add First Item"
                            ) { showAddItem = true }
                        } else {
                            EmptyStateView(
                                icon: "magnifyingglass",
                                title: "No items match",
                                message: "Try a broader filter or clear your search.",
                                actionTitle: "Clear Filters"
                            ) {
                                selectedCategory = nil
                                searchText = ""
                            }
                        }
                    } else {
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(filteredItems) { item in
                                if isSelecting {
                                    selectableCard(item)
                                } else {
                                    NavigationLink(value: item) {
                                        ItemCardView(item: item)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button { archiveItem(item) } label: {
                                            Label("Archive", systemImage: "archivebox")
                                        }
                                        Button(role: .destructive) {
                                            deleteItem(item)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Show archived items link
                    if !archivedItems.isEmpty {
                        Button {
                            showArchivedItems = true
                        } label: {
                            HStack {
                                Image(systemName: "archivebox")
                                Text("\(archivedItems.count) archived/removed items")
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .font(.callout)
                            .foregroundStyle(ColorTokens.textSecondary)
                            .padding(Spacing.md)
                            .background(ColorTokens.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.top, Spacing.sm)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.xl)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Closet")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search items")
            .navigationDestination(for: ClothingItem.self) { item in
                ItemDetailView(item: item)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: Spacing.md) {
                        Button {
                            withAnimation {
                                isSelecting.toggle()
                                if !isSelecting { selectedItems.removeAll() }
                            }
                        } label: {
                            Text(isSelecting ? "Done" : "Select")
                                .font(.callout)
                        }

                        if !isSelecting {
                            Button { showAddItem = true } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddItemView()
            }
            .sheet(isPresented: $showArchivedItems) {
                ArchivedItemsView()
            }
            .confirmationDialog(
                "Delete \(selectedItems.count) items?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteSelectedItems()
                }
            } message: {
                Text("This cannot be undone.")
            }
            // Selection toolbar at bottom
            .safeAreaInset(edge: .bottom) {
                if isSelecting && !selectedItems.isEmpty {
                    selectionToolbar
                }
            }
        }
    }

    // MARK: - Selection Toolbar
    private var selectionToolbar: some View {
        HStack(spacing: Spacing.lg) {
            Button {
                archiveSelectedItems()
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "archivebox")
                    Text("Archive")
                        .font(.caption2)
                }
            }

            Spacer()

            Text("\(selectedItems.count) selected")
                .font(.callout.bold())

            Spacer()

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "trash")
                    Text("Delete")
                        .font(.caption2)
                }
                .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.sm)
        .background(.ultraThinMaterial)
    }

    // MARK: - Selectable Card
    private func selectableCard(_ item: ClothingItem) -> some View {
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
            ItemCardView(item: item)
                .overlay(alignment: .topLeading) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? ColorTokens.warmIndigo : ColorTokens.textTertiary)
                        .background(Circle().fill(.white).padding(2))
                        .padding(6)
                }
                .opacity(isSelected ? 1 : 0.7)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    // MARK: - Filter Bar
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                filterChip("All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(ItemCategory.allCases) { category in
                    filterChip(category.displayName, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
        }
    }

    private var sortAndCountBar: some View {
        HStack {
            if isSelecting {
                Button {
                    if selectedItems.count == filteredItems.count {
                        selectedItems.removeAll()
                    } else {
                        selectedItems = Set(filteredItems.map(\.id))
                    }
                } label: {
                    Text(selectedItems.count == filteredItems.count ? "Deselect All" : "Select All")
                        .font(.footnote)
                        .foregroundStyle(ColorTokens.warmIndigo)
                }
            }

            Text("\(filteredItems.count) items")
                .font(.footnote)
                .foregroundStyle(ColorTokens.textSecondary)

            Spacer()

            Menu {
                ForEach(ClosetSortOption.allCases) { option in
                    Button {
                        sortOption = option
                    } label: {
                        HStack {
                            Text(option.rawValue)
                            if sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.arrow.down")
                    Text(sortOption.rawValue)
                }
                .font(.footnote)
                .foregroundStyle(ColorTokens.warmIndigo)
            }
        }
    }

    private func filterChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.callout)
                .padding(.horizontal, 12)
                .padding(.vertical, 8) // HIG: 44pt touch target
                .background(isSelected ? ColorTokens.warmIndigo : ColorTokens.backgroundSecondary)
                .foregroundStyle(isSelected ? .white : ColorTokens.textPrimary)
                .clipShape(Capsule())
        }
    }

    // MARK: - Actions
    private func archiveItem(_ item: ClothingItem) {
        item.status = .archived
    }

    private func deleteItem(_ item: ClothingItem) {
        modelContext.delete(item)
    }

    private func archiveSelectedItems() {
        for item in allItems where selectedItems.contains(item.id) {
            item.status = .archived
        }
        selectedItems.removeAll()
        isSelecting = false
    }

    private func deleteSelectedItems() {
        for item in allItems where selectedItems.contains(item.id) {
            modelContext.delete(item)
        }
        selectedItems.removeAll()
        isSelecting = false
    }
}

// MARK: - Archived Items View
struct ArchivedItemsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [ClothingItem]

    private var archivedItems: [ClothingItem] {
        allItems.filter { $0.status != .active }
    }

    private var groupedItems: [(status: ItemStatus, items: [ClothingItem])] {
        let grouped = Dictionary(grouping: archivedItems, by: \.status)
        return grouped.map { (status: $0.key, items: $0.value) }
            .sorted { $0.status.rawValue < $1.status.rawValue }
    }

    var body: some View {
        NavigationStack {
            Group {
                if archivedItems.isEmpty {
                    ContentUnavailableView(
                        "No archived items",
                        systemImage: "archivebox",
                        description: Text("Items you archive, donate, or mark for sale appear here.")
                    )
                } else {
                    List {
                        ForEach(groupedItems, id: \.status) { group in
                            Section(group.status.displayName) {
                                ForEach(group.items) { item in
                                    HStack {
                                        Image(systemName: item.category.icon)
                                            .frame(width: 28)
                                            .foregroundStyle(ColorTokens.warmIndigo)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name).font(.body)
                                            Text(String(format: "$%.2f", item.purchasePrice))
                                                .font(.footnote)
                                                .foregroundStyle(ColorTokens.textSecondary)
                                        }
                                        Spacer()
                                        Button("Restore") {
                                            item.status = .active
                                        }
                                        .font(.footnote)
                                        .foregroundStyle(ColorTokens.warmIndigo)
                                    }
                                }
                                .onDelete { indexSet in
                                    for i in indexSet {
                                        modelContext.delete(group.items[i])
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Archived Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
