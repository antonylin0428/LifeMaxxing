import SwiftUI

/// Simple paywall placeholder - no real purchase flow yet. Shown instead of
/// CreateCommunityView whenever the cached profile isn't premium.
struct PremiumUpsellView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Creating Communities is a Premium Feature")
                .font(.title3.bold())
                .multilineTextAlignment(.center)
            Text("Upgrade to premium to start your own community. Joining existing communities will stay free.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .navigationTitle("Premium")
    }
}
