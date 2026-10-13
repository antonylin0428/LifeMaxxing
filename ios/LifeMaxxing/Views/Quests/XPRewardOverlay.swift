import SwiftUI

/// Renders ONLY what the server returned from POST /tasks/complete -
/// never a locally-guessed XP/streak/rank value.
struct XPRewardOverlay: View {
    let result: CompleteTaskResult

    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.highlight.opacity(0.3))
                        .frame(width: 72, height: 72)
                    Text("+\(result.finalXPAwarded)")
                        .font(Theme.font(29))
                        .foregroundStyle(Theme.ink)
                }

                VStack(spacing: 6) {
                    Text("XP Earned!")
                        .font(Theme.font(19))
                        .foregroundStyle(Theme.textPrimary)
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .font(Theme.font(13))
                        Text("Streak: \(result.newStreak) days (\(String(format: "%.2f", result.newMultiplier))x)")
                            .font(Theme.font(14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                if result.rankChanged {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(Color(hex: "E8A000"))
                        Text("Rank up! \(result.newRank.displayName)")
                            .font(Theme.font(15))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "FFE07A").opacity(0.5))
                    .clipShape(Capsule())
                }

                Text("Tap to dismiss")
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(28)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 32, x: 0, y: 12)
            .frame(maxWidth: 300)
        }
    }
}
