import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab: Tab = .today

    enum Tab: String {
        case today, closet, insights, profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }
                .tag(Tab.today)

            ClosetGridView()
                .tabItem {
                    Label("Closet", systemImage: "rectangle.grid.2x2")
                }
                .tag(Tab.closet)

            InsightsDashboardView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar")
                }
                .tag(Tab.insights)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(Tab.profile)
        }
        .tint(ColorTokens.brandPrimary)
    }
}

struct ProfileView: View {
    @Query private var items: [ClothingItem]
    @AppStorage("monthlySpendTarget") private var monthlySpendTarget: Double = 150
    @AppStorage("utilizationTarget") private var utilizationTarget: Double = 70
    @State private var isEditingGoals = false
    @State private var showExport = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            List {
                Section("Goals") {
                    HStack {
                        Text("Monthly spend target")
                        Spacer()
                        Text("$\(Int(monthlySpendTarget))")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                    HStack {
                        Text("Utilization target")
                        Spacer()
                        Text("\(Int(utilizationTarget))%")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                    Button("Edit Goals") {
                        isEditingGoals = true
                    }
                }
                Section("Data") {
                    Button("Export Wardrobe Data") {
                        exportURL = generateCSV()
                        if exportURL != nil { showExport = true }
                    }
                }
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(ColorTokens.textSecondary)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isEditingGoals) {
                NavigationStack {
                    Form {
                        Section("Monthly Spend Target") {
                            Stepper("$\(Int(monthlySpendTarget))", value: $monthlySpendTarget, in: 0...10000, step: 25)
                        }
                        Section("Utilization Target") {
                            Stepper("\(Int(utilizationTarget))%", value: $utilizationTarget, in: 0...100, step: 5)
                        }
                    }
                    .navigationTitle("Edit Goals")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { isEditingGoals = false }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showExport) {
                if let url = exportURL {
                    ShareSheet(url: url)
                }
            }
        }
    }

    private func generateCSV() -> URL? {
        var csv = "Name,Category,Color,Purchase Price,Purchase Date,Total Wears,Cost Per Wear,Status\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        for item in items {
            let row = [
                item.name,
                item.category.displayName,
                item.color,
                String(format: "%.2f", item.purchasePrice),
                dateFormatter.string(from: item.purchaseDate),
                "\(item.totalWears)",
                String(format: "%.2f", item.costPerWear),
                item.status.displayName
            ].map { "\"\($0)\"" }.joined(separator: ",")
            csv += row + "\n"
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("threadline-export.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
