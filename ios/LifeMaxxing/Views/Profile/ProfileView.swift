import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    if let user = viewModel.user {
                        profileHeader(user: user)
                        statsRow(user: user)
                        streaksSection
                        settingsSection(user: user)
                    }
                    signOutButton
                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .refreshable { await viewModel.load() }
            .overlay {
                if viewModel.isLoading && viewModel.user == nil { LoadingView() }
            }
        }
        .navigationTitle("Profile")
        .task { await viewModel.load() }
    }

    // MARK: Header

    private func profileHeader(user: User) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "E8E8E4"))
                    .frame(width: 80, height: 80)
                Text(String(user.username.prefix(1)).uppercased())
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }

            Text(user.username)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text(user.rank.displayName)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Color(hex: "7A5C00"))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color(hex: "FFE07A").opacity(0.7))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .cardStyle()
    }

    // MARK: Stats

    private func statsRow(user: User) -> some View {
        let bestStreak = viewModel.categories.map(\.currentStreak).max() ?? 0
        let activeCount = viewModel.categories.filter { $0.enabled != false }.count

        return HStack(spacing: 10) {
            StatTile(value: "\(user.totalXP)", label: "Total XP", color: Color(hex: "C5B5F5"))
            StatTile(value: "\(bestStreak)d", label: "Best Streak", color: Color(hex: "A8D4F5"))
            StatTile(value: "\(activeCount)", label: "Active", color: Color(hex: "B0E8AC"))
        }
    }

    // MARK: Streaks

    private var streaksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Streaks")
            VStack(spacing: 8) {
                ForEach(viewModel.categories) { category in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(category.categoryId.color.opacity(0.6))
                                .frame(width: 34, height: 34)
                            Image(systemName: category.categoryId.systemImageName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.ink)
                        }

                        Text(category.categoryId.displayName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 3) {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(.orange)
                                    .font(.system(size: 10))
                                Text("\(category.currentStreak)d")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            Text("best: \(category.longestStreak)d")
                                .font(.system(size: 10))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    .padding(12)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
                }
            }
        }
    }

    // MARK: Settings

    private func settingsSection(user: User) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Settings")

            VStack(spacing: 0) {
                NavigationLink {
                    CategorySetupView()
                } label: {
                    SettingsRow(icon: "slider.horizontal.3", label: "Category Settings")
                }

                Divider()
                    .padding(.horizontal, 16)

                NavigationLink {
                    if user.isPremium { CreateCommunityView() } else { PremiumUpsellView() }
                } label: {
                    SettingsRow(icon: "person.3.fill", label: "Create Community")
                }

                #if DEBUG
                Divider()
                    .padding(.horizontal, 16)

                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Theme.surfaceSecondary)
                            .frame(width: 30, height: 30)
                        Image(systemName: "wrench.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    Text("Premium (mock)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { user.isPremium },
                        set: { v in Task { await viewModel.setMockPremium(v) } }
                    ))
                    .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                #endif
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        }
    }

    // MARK: Sign Out

    private var signOutButton: some View {
        Button {
            Task { await authViewModel.signOut() }
        } label: {
            Text("Sign Out")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: "FF4444"))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(hex: "FF4444").opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}
