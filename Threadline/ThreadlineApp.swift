import SwiftUI
import SwiftData

@main
struct ThreadlineApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [ClothingItem.self, WearLog.self])
    }
}
