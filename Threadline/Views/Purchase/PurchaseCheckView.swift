import SwiftUI
import SwiftData
import PhotosUI

struct PurchaseCheckView: View {
    @Query private var allItems: [ClothingItem]
    private var items: [ClothingItem] {
        allItems.filter { $0.status == .active }
    }
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: ItemCategory?
    @State private var estimatedPrice = ""
    @State private var showResult = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showCamera = false

    private var similarItems: [ClothingItem] {
        guard let cat = selectedCategory else { return [] }
        return items.filter { $0.category == cat }
    }

    private var categoryAvgCPW: Double {
        let catItems = similarItems.filter { $0.totalWears > 0 }
        guard !catItems.isEmpty else { return 0 }
        return catItems.reduce(0.0) { $0 + $1.costPerWear } / Double(catItems.count)
    }

    private let thumbColumns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.md) {
                    photoSection

                    // Step 1: Category - this is what actually drives the comparison
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("What type of item is it?")
                            .font(.headline)
                        categoryGrid
                    }

                    // Step 2: Price
                    if selectedCategory != nil {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("How much is it?")
                                .font(.headline)
                            HStack {
                                Text("$")
                                    .foregroundStyle(ColorTokens.textSecondary)
                                TextField("0.00", text: $estimatedPrice)
                                    .keyboardType(.decimalPad)
                            }
                            .font(.body)
                            .padding(Spacing.sm)
                            .background(ColorTokens.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Check button
                    if selectedCategory != nil && !estimatedPrice.isEmpty {
                        Button {
                            withAnimation(.spring(response: 0.35)) { showResult = true }
                        } label: {
                            Text("Check My Closet")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .background(ColorTokens.warmIndigo)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if showResult {
                        resultCard
                        if !similarItems.isEmpty {
                            youAlreadyOwnSection
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.xxl)
                .animation(.spring(response: 0.35), value: selectedCategory != nil)
                .animation(.spring(response: 0.35), value: showResult)
            }
            .navigationTitle("Should I Buy This?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
            .onChange(of: selectedCategory) { _, _ in
                showResult = false
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView(photoData: $photoData)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Category Grid (the real input)
    private var categoryGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ], spacing: 8) {
            ForEach(ItemCategory.allCases) { cat in
                let isSelected = selectedCategory == cat
                let count = items.filter { $0.category == cat }.count
                Button {
                    withAnimation(.spring(response: 0.2)) {
                        selectedCategory = cat
                        showResult = false
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: cat.icon)
                            .font(.body)
                        Text(cat.displayName)
                            .font(.footnote)
                        if count > 0 {
                            Text("\(count) owned")
                                .font(.footnote)
                                .foregroundStyle(isSelected ? .white.opacity(0.7) : ColorTokens.textTertiary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 64)
                    .background(isSelected ? ColorTokens.warmIndigo : ColorTokens.backgroundSecondary)
                    .foregroundStyle(isSelected ? .white : ColorTokens.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .sensoryFeedback(.selection, trigger: isSelected)
            }
        }
    }

    // MARK: - Photo Section
    private var photoSection: some View {
        VStack(spacing: Spacing.sm) {
            if let photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .topTrailing) {
                        Button {
                            self.photoData = nil
                            self.selectedPhotoItem = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .black.opacity(0.6))
                                .padding(8)
                        }
                    }
                HStack {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Choose Different", systemImage: "photo.on.rectangle.angled")
                            .font(.footnote)
                    }
                    Spacer()
                    Button { showCamera = true } label: {
                        Label("Retake", systemImage: "camera")
                            .font(.footnote)
                    }
                }
            } else {
                Button { showCamera = true } label: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ColorTokens.backgroundSecondary)
                        .frame(height: 140)
                        .overlay {
                            VStack(spacing: Spacing.xs) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                    .foregroundStyle(ColorTokens.warmIndigo)
                                Text("Snap a photo (optional)")
                                    .font(.callout)
                                    .foregroundStyle(ColorTokens.textSecondary)
                            }
                        }
                }

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Or choose from library", systemImage: "photo.on.rectangle.angled")
                        .font(.footnote)
                        .foregroundStyle(ColorTokens.textTertiary)
                }
            }
        }
    }

    // MARK: - Result Card
    private var resultCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Verdict
            HStack {
                Image(systemName: verdictIcon)
                    .foregroundStyle(verdictColor)
                Text(verdictTitle)
                    .font(.headline)
            }

            Text(verdictMessage)
                .font(.callout)
                .foregroundStyle(ColorTokens.textSecondary)

            Divider()

            // CPW projection
            if let price = Double(estimatedPrice) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Cost-per-wear projection")
                        .font(.footnote)
                        .foregroundStyle(ColorTokens.textTertiary)
                    HStack(spacing: Spacing.lg) {
                        cpwProjection(price: price, wears: 10, color: ColorTokens.warmIndigo)
                        cpwProjection(price: price, wears: 30, color: ColorTokens.sage)
                        if categoryAvgCPW > 0 {
                            VStack {
                                Text(String(format: "$%.2f", categoryAvgCPW))
                                    .font(.footnote.monospaced().bold())
                                    .foregroundStyle(ColorTokens.warning)
                                Text("your avg")
                                    .font(.footnote)
                                    .foregroundStyle(ColorTokens.textTertiary)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(ColorTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sensoryFeedback(.impact, trigger: showResult)
    }

    private func cpwProjection(price: Double, wears: Int, color: Color) -> some View {
        VStack {
            Text(String(format: "$%.2f", price / Double(wears)))
                .font(.footnote.monospaced().bold())
                .foregroundStyle(color)
            Text("at \(wears) wears")
                .font(.footnote)
                .foregroundStyle(ColorTokens.textTertiary)
        }
    }

    // MARK: - "You Already Own" section
    private var youAlreadyOwnSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let cat = selectedCategory {
                Text("Your \(cat.displayName.lowercased()) (\(similarItems.count))")
                    .font(.headline)
            }

            LazyVGrid(columns: thumbColumns, spacing: 6) {
                ForEach(similarItems) { item in
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 6)
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
                                        .font(.footnote)
                                        .foregroundStyle(ColorTokens.textTertiary)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text(item.name)
                            .font(.footnote)
                            .lineLimit(1)
                        Text("\(item.totalWears) wears")
                            .font(.footnote)
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(ColorTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Verdict logic
    private var verdictIcon: String {
        if similarItems.count >= 5 { return "exclamationmark.triangle.fill" }
        if similarItems.count >= 3 { return "hand.raised.fill" }
        return "checkmark.circle.fill"
    }

    private var verdictColor: Color {
        if similarItems.count >= 5 { return ColorTokens.error }
        if similarItems.count >= 3 { return ColorTokens.warning }
        return ColorTokens.sage
    }

    private var verdictTitle: String {
        if similarItems.count >= 5 { return "You probably don't need this" }
        if similarItems.count >= 3 { return "Think twice" }
        if similarItems.count == 0 { return "New category - go for it" }
        return "Could be a good add"
    }

    private var verdictMessage: String {
        guard let cat = selectedCategory else { return "" }
        let name = cat.displayName.lowercased()
        if similarItems.count >= 5 {
            return "You already own \(similarItems.count) \(name). That's a lot of overlap."
        }
        if similarItems.count >= 3 {
            return "You own \(similarItems.count) \(name). Check if any of them already fill this role."
        }
        if similarItems.count == 0 {
            return "You don't own any \(name) yet. This fills a gap."
        }
        return "You own \(similarItems.count) \(name). There's room if this one earns its place."
    }
}
