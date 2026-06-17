import SwiftUI

/// Renders ONLY what the server returned from POST /tasks/complete - never
/// a locally-guessed XP/streak/rank value.
struct XPRewardOverlay: View {
    let result: CompleteTaskResult

    var body: some View {
        VStack(spacing: 8) {
            Text("+\(result.finalXPAwarded) XP")
                .font(.title.bold())
            Text("Streak: \(result.newStreak) days (\(String(format: "%.2f", result.newMultiplier))x)")
                .font(.subheadline)
            if result.rankChanged {
                Text("Rank up! \(result.newRank.displayName)")
                    .font(.headline)
                    .foregroundStyle(.yellow)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8)
    }
}
