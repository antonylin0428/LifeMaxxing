import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Logo + branding
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Theme.ink)
                                .frame(width: 96, height: 96)
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundStyle(Theme.highlight)
                        }

                        VStack(spacing: 10) {
                            Text("LifeMaxxing")
                                .font(.system(size: 34, weight: .black, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                            Text("Complete daily goals.\nEarn XP. Rank up.")
                                .font(.system(size: 16))
                                .foregroundStyle(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    Spacer()

                    // Feature chips
                    HStack(spacing: 12) {
                        featureChip(icon: "figure.strengthtraining.traditional",
                                    label: "Train Daily",
                                    color: Color(hex: "FFE07A"))
                        featureChip(icon: "trophy.fill",
                                    label: "Rank Up",
                                    color: Color(hex: "C5B5F5"))
                        featureChip(icon: "person.2.fill",
                                    label: "Compete",
                                    color: Color(hex: "A8D4F5"))
                    }
                    .padding(.bottom, 48)

                    // Buttons
                    VStack(spacing: 12) {
                        NavigationLink { SignUpView() } label: {
                            Text("Get Started")
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        NavigationLink { SignInView() } label: {
                            Text("Sign In")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func featureChip(icon: String, label: String, color: Color) -> some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(color)
                    .frame(width: 60, height: 60)
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Theme.ink)
            }
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
