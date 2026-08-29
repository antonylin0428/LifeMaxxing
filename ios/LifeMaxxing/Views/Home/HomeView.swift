import SwiftUI

/// Dashboard overview — all XP/rank/streak values come from the server
/// (GET /me and GET /me/categories). Nothing is computed client-side.
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
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .lmBackground()
        .refreshable { await viewModel.load() }
        .overlay {
            if viewModel.isLoading && viewModel.user == nil { LoadingView() }
        }
        .task { await viewModel.load() }
        .safeAreaInset(edge: .bottom) {
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Self.todayDateLabel)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                Text("Hey, \(viewModel.user?.username ?? "there") 👋")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            Spacer()
            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .font(.system(size: 14, weight: .bold))
                Text("\(viewModel.bestCurrentStreak)d streak")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Theme.surface)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }

    // MARK: Rank Card

    private var rankCard: some View {
        let rank = viewModel.user?.rank ?? .lowTierNormie1
        let totalXP = viewModel.user?.totalXP ?? 0
        let next = rank.next

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT RANK")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .tracking(1)
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(Color(hex: "E8A000"))
                            .font(.system(size: 16, weight: .bold))
                        Text(rank.displayName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("TOTAL XP")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .tracking(1)
                    Text("\(totalXP)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                }
            }

            if let next {
                let span = max(next.xpRequired - rank.xpRequired, 1)
                let progress = Double(min(max(totalXP - rank.xpRequired, 0), span)) / Double(span)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("\(totalXP - rank.xpRequired) / \(span) XP to next rank")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text(next.displayName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Theme.surfaceSecondary)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Theme.highlight)
                                .frame(width: geo.size.width * CGFloat(progress), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.highlight)
                    Text("Maximum rank achieved")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
        .cardStyle()
    }

    // MARK: Today's Progress

    private var todaysProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Progress")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.textPrimary)

            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.categories) { category in
                    progressCard(for: category)
                }
            }
        }
    }

    private func progressCard(for category: CategoryStat) -> some View {
        let done = viewModel.isCompletedToday(category)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(done ? Theme.surfaceSecondary : category.categoryId.color)
                        .frame(width: 32, height: 32)
                    Image(systemName: category.categoryId.systemImageName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(done ? Theme.textSecondary : Theme.ink)
                }
                Spacer()
                if category.categoryId.isOptional {
                    Text("opt")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Theme.surfaceSecondary)
                        .clipShape(Capsule())
                }
            }
            Text(category.categoryId.displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(done ? Theme.textSecondary : Theme.textPrimary)
                .lineLimit(2)
            Text(done ? "Done ✓" : "Not logged")
                .font(.system(size: 11))
                .foregroundStyle(done ? Theme.accentGreen : Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(done ? 0.02 : 0.05), radius: 8, x: 0, y: 3)
        .opacity(done ? 0.75 : 1)
    }

    // MARK: Achievements

    private var achievements: some View {
        let unlockedCount = viewModel.achievements.filter(\.isUnlocked).count

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(unlockedCount)/\(viewModel.achievements.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.achievements) { achievement in
                        VStack(spacing: 7) {
                            ZStack {
                                Circle()
                                    .fill(achievement.isUnlocked
                                          ? Color(hex: "FFE07A").opacity(0.6)
                                          : Theme.surfaceSecondary)
                                    .frame(width: 52, height: 52)
                                Image(systemName: achievement.iconName)
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundStyle(achievement.isUnlocked
                                                     ? Color(hex: "8A6000")
                                                     : Theme.textSecondary)
                            }
                            .opacity(achievement.isUnlocked ? 1 : 0.4)
                            Text(achievement.title)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .frame(width: 60)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .cardStyle()
    }

    private static var todayDateLabel: String {
        let f = DateFormatter()
        f.dateStyle = .full
        return f.string(from: Date())
    }
}
