import SwiftUI
import SwiftData
import PhotosUI

enum ClothingColor: String, CaseIterable, Identifiable {
    case black = "Black"
    case white = "White"
    case gray = "Gray"
    case navy = "Navy"
    case blue = "Blue"
    case lightBlue = "Light Blue"
    case red = "Red"
    case burgundy = "Burgundy"
    case pink = "Pink"
    case orange = "Orange"
    case rust = "Rust"
    case yellow = "Yellow"
    case green = "Green"
    case olive = "Olive"
    case brown = "Brown"
    case tan = "Tan"
    case beige = "Beige"
    case cream = "Cream"
    case purple = "Purple"
    case lavender = "Lavender"
    case charcoal = "Charcoal"
    case multicolor = "Multicolor"
    case other = "Other"

    var id: String { rawValue }

    var swatchColor: Color {
        switch self {
        case .black: return .black
        case .white: return .white
        case .gray: return .gray
        case .navy: return Color(red: 0, green: 0, blue: 0.5)
        case .blue: return .blue
        case .lightBlue: return Color(red: 0.68, green: 0.85, blue: 0.9)
        case .red: return .red
        case .burgundy: return Color(red: 0.5, green: 0, blue: 0.13)
        case .pink: return .pink
        case .orange: return .orange
        case .rust: return Color(red: 0.72, green: 0.25, blue: 0.05)
        case .yellow: return .yellow
        case .green: return .green
        case .olive: return Color(red: 0.5, green: 0.5, blue: 0)
        case .brown: return .brown
        case .tan: return Color(red: 0.82, green: 0.71, blue: 0.55)
        case .beige: return Color(red: 0.96, green: 0.96, blue: 0.86)
        case .cream: return Color(red: 1, green: 0.99, blue: 0.82)
        case .purple: return .purple
        case .lavender: return Color(red: 0.73, green: 0.63, blue: 0.96)
        case .charcoal: return Color(red: 0.21, green: 0.27, blue: 0.31)
        case .multicolor: return .clear
        case .other: return .clear
        }
    }
}

struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: ItemCategory?
    @State private var purchasePrice = ""
    @State private var purchaseDate = Date.now
    @State private var selectedColor: ClothingColor?
    @State private var customColor = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showCamera = false

    private var colorString: String {
        guard let color = selectedColor else { return "" }
        return color == .other ? customColor : color.rawValue
    }

    private var canSave: Bool {
        !name.isEmpty && category != nil && !purchasePrice.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Photo Section
                Section {
                    if let photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
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
                    }

                    // Distinct buttons with clear labels and icons
                    HStack {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("Choose from Library")
                            }
                            .font(.body)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 44)
                            .background(ColorTokens.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    Button {
                        showCamera = true
                    } label: {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Take a Photo")
                        }
                        .font(.body)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .background(ColorTokens.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } header: {
                    Text("Photo")
                } footer: {
                    Text("Add a photo so you can quickly identify items when logging outfits.")
                }

                // MARK: - Item Details
                Section("Item Details") {
                    TextField("Item name", text: $name)
                        .font(.body)

                    // Category with "Select" prompt (no default)
                    Picker("Category", selection: $category) {
                        Text("Select category").tag(nil as ItemCategory?)
                        ForEach(ItemCategory.allCases) { cat in
                            Text(cat.displayName).tag(cat as ItemCategory?)
                        }
                    }
                    .font(.body)

                    // Color with "Select" prompt (no default)
                    Picker("Color", selection: $selectedColor) {
                        Text("Select color").tag(nil as ClothingColor?)
                        ForEach(ClothingColor.allCases) { color in
                            HStack(spacing: 8) {
                                if color.swatchColor != .clear {
                                    Circle()
                                        .fill(color.swatchColor)
                                        .frame(width: 14, height: 14)
                                        .overlay(Circle().stroke(Color.gray.opacity(0.3), lineWidth: 0.5))
                                }
                                Text(color.rawValue)
                            }
                            .tag(color as ClothingColor?)
                        }
                    }
                    .font(.body)

                    if selectedColor == .other {
                        TextField("Enter custom color", text: $customColor)
                            .font(.body)
                    }
                }

                // MARK: - Purchase Info
                Section {
                    HStack {
                        Text("$")
                            .font(.body)
                            .foregroundStyle(ColorTokens.textSecondary)
                        TextField("0.00", text: $purchasePrice)
                            .keyboardType(.decimalPad)
                            .font(.body)
                    }

                    DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                        .font(.body)
                } header: {
                    Text("Purchase Info")
                } footer: {
                    Text("Price is used to calculate cost-per-wear in Insights.")
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                        dismiss()
                    }
                    .bold()
                    .disabled(!canSave)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView(photoData: $photoData)
                    .ignoresSafeArea()
            }
        }
    }

    private func saveItem() {
        let price = Double(purchasePrice) ?? 0
        let item = ClothingItem(
            name: name,
            category: category ?? .tops,
            purchasePrice: price,
            purchaseDate: purchaseDate,
            photoData: photoData,
            color: colorString
        )
        modelContext.insert(item)
    }
}

// MARK: - Camera Picker
struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var photoData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.photoData = image.jpegData(compressionQuality: 0.8)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
