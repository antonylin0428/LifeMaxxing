import SwiftUI

struct UserProfileView: View {
    let sub: String
    let initialUsername: String?

    @State private var viewModel: UserProfileViewModel
    @State private var selectedAchievement: Achievement?

    init(sub: String, initialUsername: String? = nil) {
        self.sub = sub
        self.initialUsername = initialUsername
        _viewModel = State(initialValue: UserProfileViewModel(sub: sub))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if viewModel.isLoading && viewModel.profile == nil {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let profile = viewModel.profile {
                content(profile: profile)
            } else if let err = viewModel.errorMessage {
                Text(err)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(20)
            }
        }
        .navigationTitle(viewModel.profile?.username ?? initialUsername ?? "Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .sheet(item: $selectedAchievement) { a in
            AchievementDetailSheet(achievement: a)
        }
    }

    private func content(profile: PublicUserProfile) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard(profile: profile)
                achievementsSection
                if let photoUrl = profile.recentGymPhotoUrl {
                    recentGymPhoto(url: photoUrl, date: profile.recentGymPhotoDate)
                }
            }
            .padding(20)
        }
    }

    // MARK: - Header

    private func headerCard(profile: PublicUserProfile) -> some View {
        VStack(spacing: 14) {
            avatarView(profile: profile)

            Text(profile.username)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.textPrimary)

            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text(profile.rank.displayName)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Color(hex: "7A5C00"))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color(hex: "FFE07A").opacity(0.7))
            .clipShape(Capsule())

            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "C5B5F5"))
                Text("\(profile.totalXP) XP")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .cardStyle()
    }

    @ViewBuilder
    private func avatarView(profile: PublicUserProfile) -> some View {
        if let urlString = profile.avatarUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                        .frame(width: 88, height: 88).clipShape(Circle())
                default:
                    initialsCircle(username: profile.username)
                }
            }
        } else {
            initialsCircle(username: profile.username)
        }
    }

    private func initialsCircle(username: String) -> some View {
        ZStack {
            Circle().fill(Color(hex: "E8E8E4")).frame(width: 88, height: 88)
            Text(String(username.prefix(1)).uppercased())
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    // MARK: - Achievements

    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Achievements")
            AchievementsGrid(achievements: viewModel.achievements) { achievement in
                selectedAchievement = achievement
            }
            .cardStyle()
        }
    }

    // MARK: - Recent Gym Photo

    private func recentGymPhoto(url: String, date: String?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: "Recent Workout")
                Spacer()
                if let date {
                    Text(date)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            AsyncImage(url: URL(string: url)) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                        .frame(maxWidth: .infinity).frame(height: 240).clipped()
                case .failure:
                    Color(hex: "E8E8E4").frame(maxWidth: .infinity).frame(height: 240)
                        .overlay(Image(systemName: "photo").foregroundStyle(Theme.textSecondary))
                default:
                    Color(hex: "E8E8E4").frame(maxWidth: .infinity).frame(height: 240)
                        .overlay(ProgressView())
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        }
    }
}

// MARK: - Shared Achievements Grid

struct AchievementsGrid: View {
    let achievements: [Achievement]
    var onTap: ((Achievement) -> Void)? = nil

    private let columns = [GridItem(.adaptive(minimum: 64), spacing: 12)]

    var body: some View {
        if achievements.isEmpty {
            Text("No achievements yet")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
        } else {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(achievements) { achievement in
                    AchievementBadge(achievement: achievement)
                        .onTapGesture { onTap?(achievement) }
                }
            }
            .padding(16)
        }
    }
}

struct AchievementBadge: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked
                          ? Color(hex: "FFE07A").opacity(0.8)
                          : Theme.surfaceSecondary)
                    .frame(width: 56, height: 56)
                Image(systemName: achievement.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(achievement.isUnlocked
                                     ? Color(hex: "7A5C00")
                                     : Theme.textSecondary.opacity(0.4))
            }
            Text(achievement.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(achievement.isUnlocked ? Theme.textPrimary : Theme.textSecondary.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 64)
        }
    }
}

// MARK: - Achievement Detail Sheet

struct AchievementDetailSheet: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 28) {
            Capsule()
                .fill(Theme.surfaceSecondary)
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            ZStack {
                Circle()
                    .fill(achievement.isUnlocked
                          ? Color(hex: "FFE07A").opacity(0.8)
                          : Theme.surfaceSecondary)
                    .frame(width: 100, height: 100)
                Image(systemName: achievement.iconName)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(achievement.isUnlocked
                                     ? Color(hex: "7A5C00")
                                     : Theme.textSecondary.opacity(0.4))
            }

            VStack(spacing: 10) {
                Text(achievement.title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)

                Text(achievement.description)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if achievement.isUnlocked {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.accentGreen)
                    Text("Unlocked")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.accentGreen)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Theme.accentGreen.opacity(0.12))
                .clipShape(Capsule())
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Theme.textSecondary)
                    Text("Locked")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Theme.surfaceSecondary)
                .clipShape(Capsule())
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Theme.background.ignoresSafeArea())
        .presentationDetents([.height(380)])
        .presentationDragIndicator(.hidden)
    }
}
