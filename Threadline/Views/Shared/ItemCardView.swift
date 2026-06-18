import SwiftUI

struct ItemCardView: View {
    let item: ClothingItem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
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
                            .font(.title3)
                            .foregroundStyle(ColorTokens.textTertiary)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if item.isUnderperforming {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(ColorTokens.warning)
                            .padding(4)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(item.name)
                .font(.callout)
                .lineLimit(1)

            HStack(spacing: 3) {
                Text(String(format: "$%.2f", item.costPerWear))
                    .font(.footnote.monospaced())
                    .foregroundStyle(item.costPerWear < 10 ? ColorTokens.sage : ColorTokens.textSecondary)
                Text("·")
                    .foregroundStyle(ColorTokens.textTertiary)
                    .font(.footnote)
                Text("\(item.totalWears) wears")
                    .font(.footnote)
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
    }
}
