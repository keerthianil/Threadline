import Foundation
import SwiftData

@Model
final class WearLog {
    var id: UUID
    var date: Date
    var occasion: String?
    var item: ClothingItem?

    init(date: Date = .now, occasion: String? = nil, item: ClothingItem? = nil) {
        self.id = UUID()
        self.date = date
        self.occasion = occasion
        self.item = item
    }
}
