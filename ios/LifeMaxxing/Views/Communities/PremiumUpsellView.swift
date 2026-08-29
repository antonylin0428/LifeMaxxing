import SwiftUI

/// Paywall placeholder — no real purchase flow yet. Shown instead of
/// CreateCommunityView when the user's profile isn't premium.
struct PremiumUpsellView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 32) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "C5B5F5").opacity(0.4))
                        .frame(width: 100, height: 100)
                    Image(systemName: "star.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(Color(hex: "7A5CF5"))
                }

                // Copy
                VStack(spacing: 12) {
                    Text("Unlock Premium")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Create your own community and challenge people to compete with you. Joining communities is always free.")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                // Feature list
                VStack(alignment: .leading, spacing: 12) {
                    premiumFeature(icon: "person.3.fill", text: "Create unlimited communities")
                    premiumFeature(icon: "chart.bar.fill", text: "Community leaderboards")
                    premiumFeature(icon: "crown.fill", text: "Premium badge on your profile")
                }
                .padding(20)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)

                // CTA
                Button("Upgrade to Premium") {}
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 8)

                Text("Coming soon")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(28)
        }
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func premiumFeature(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "C5B5F5").opacity(0.4))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "7A5CF5"))
            }
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
        }
    }
}
