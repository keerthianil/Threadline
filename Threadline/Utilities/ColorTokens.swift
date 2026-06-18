import SwiftUI

enum ColorTokens {
    // Brand (from Asset Catalog)
    static let brandPrimary = Color("BrandPrimary")
    static let brandAccent = Color("BrandAccent")

    // Backgrounds (system adaptive)
    static let backgroundPrimary = Color(.systemBackground)
    static let backgroundSecondary = Color(.secondarySystemBackground)
    static let backgroundTertiary = Color(.tertiarySystemBackground)

    // Text (system adaptive)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)

    // Semantic
    static let success = Color.green
    static let error = Color.red
    static let warning = Color.orange
    static let info = Color.blue

    // Borders
    static let borderDefault = Color(.separator)

    // Threadline brand shortcuts
    static let warmIndigo = Color(red: 74/255, green: 61/255, blue: 143/255)
    static let sage = Color(red: 122/255, green: 158/255, blue: 126/255)
}
