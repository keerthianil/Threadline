import SwiftUI

struct HealthScoreRing: View {
    let score: Int
    let size: CGFloat

    @State private var animatedProgress: Double = 0

    private var progress: Double {
        Double(score) / 100.0
    }

    private var scoreColor: Color {
        switch score {
        case 80...100: return ColorTokens.sage
        case 60..<80: return ColorTokens.warmIndigo
        case 40..<60: return ColorTokens.warning
        default: return ColorTokens.error
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(ColorTokens.backgroundSecondary, lineWidth: size * 0.1)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    scoreColor,
                    style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                    .foregroundStyle(scoreColor)
                Text("/ 100")
                    .font(.system(size: size * 0.12, weight: .regular))
                    .foregroundStyle(ColorTokens.textSecondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Wardrobe health score: \(score) out of 100")
    }
}
