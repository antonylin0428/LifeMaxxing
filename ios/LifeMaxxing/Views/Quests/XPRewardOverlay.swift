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
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.ink)
                }

                VStack(spacing: 6) {
                    Text("XP Earned!")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 12))
                        Text("Streak: \(result.newStreak) days (\(String(format: "%.2f", result.newMultiplier))x)")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                if result.rankChanged {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(Color(hex: "E8A000"))
                        Text("Rank up! \(result.newRank.displayName)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: "FFE07A").opacity(0.5))
                    .clipShape(Capsule())
                }

                Text("Tap to dismiss")
                    .font(.system(size: 11))
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
