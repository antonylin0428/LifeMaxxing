import SwiftUI

/// The dashboard overview tab, matching brand/Screenshot 2026-06-19 at
/// 2.22.10 PM.png. All XP/rank/streak values come from GET /me and
/// GET /me/categories - nothing here is computed client-side. The
/// Achievements row is the one exception: it's local mock data (see
/// Achievement.swift) until a backend model exists.
struct HomeView: View {
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                rankCard
                todaysProgress
                achievements
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .overlay {
            if viewModel.isLoading { LoadingView() }
        }
        .task { await viewModel.load() }
        .safeAreaInset(edge: .bottom) {
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error).padding()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Self.todayDateLabel)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                Text("Hey, \(viewModel.user?.username ?? "there") 👋")
                    .font(.title2.bold())
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(viewModel.bestCurrentStreak) day streak")
                    .font(.subheadline.bold())
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.surfaceElevated)
            .clipShape(Capsule())
        }
    }

    private var rankCard: some View {
        let rank = viewModel.user?.rank ?? .lowTierNormie1
        let totalXP = viewModel.user?.totalXP ?? 0
        let next = rank.next

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT RANK")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.textSecondary)
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(Theme.accentGold)
                        Text(rank.displayName)
                            .font(.title3.bold())
                            .foregroundStyle(Theme.accentGold)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("TOTAL XP")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.textSecondary)
                    Text("\(totalXP)")
                        .font(.title3.bold())
                        .foregroundStyle(Theme.textPrimary)
                }
            }

            if let next {
                let span = max(next.xpRequired - rank.xpRequired, 1)
                let progress = Double(min(max(totalXP - rank.xpRequired, 0), span)) / Double(span)

                VStack(alignment: .leading, spacing: 6) {
                    Text("\(totalXP - rank.xpRequired) / \(span) XP")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    ProgressView(value: progress)
                        .tint(Theme.accentGold)
                    Text("\(next.displayName) \u{2192}")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.accentGold)
                }
            } else {
                Text("Max rank reached")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.accentGold)
            }
        }
        .cardStyle()
    }

    private var todaysProgress: some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible())]

        return VStack(alignment: .leading, spacing: 12) {
            Text("Today's Progress")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.categories) { category in
                    progressCard(for: category)
                }
            }
        }
    }

    private func progressCard(for category: CategoryStat) -> some View {
        let done = viewModel.isCompletedToday(category)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: category.categoryId.systemImageName)
                    .foregroundStyle(done ? Theme.accentPurple : Theme.textSecondary)
                Spacer()
                if category.categoryId.isOptional {
                    Text("opt")
                        .font(.caption2.bold())
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.surfaceElevated)
                        .clipShape(Capsule())
                }
            }
            Text(category.categoryId.displayName)
                .font(.subheadline.bold())
                .foregroundStyle(Theme.textPrimary)
            Text(done ? "Done" : "Not logged")
                .font(.caption)
                .foregroundStyle(done ? Theme.accentPurple : Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var achievements: some View {
        let unlockedCount = viewModel.achievements.filter(\.isUnlocked).count

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(unlockedCount) / \(viewModel.achievements.count) unlocked")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.achievements) { achievement in
                        VStack(spacing: 6) {
                            Image(systemName: achievement.iconName)
                                .font(.title3)
                                .foregroundStyle(achievement.isUnlocked ? Theme.accentGold : Theme.textSecondary)
                                .frame(width: 48, height: 48)
                                .background(Theme.surfaceElevated)
                                .clipShape(Circle())
                                .opacity(achievement.isUnlocked ? 1 : 0.4)
                            Text(achievement.title)
                                .font(.caption2)
                                .foregroundStyle(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .frame(width: 64)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private static var todayDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
}
