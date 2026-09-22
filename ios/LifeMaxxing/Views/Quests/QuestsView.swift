import SwiftUI

struct QuestsView: View {
    @State private var viewModel = QuestsViewModel()

    private var coreCategories: [CategoryStat] {
        viewModel.categories.filter { !$0.categoryId.isOptional }
    }

    private var optionalCategories: [CategoryStat] {
        viewModel.categories.filter { $0.categoryId.isOptional }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Personal & Community section
                    questSection(
                        title: "Personal & Community",
                        subtitle: "XP from these counts toward community leaderboards",
                        icon: "trophy.fill",
                        iconColor: Color(hex: "FFD700"),
                        categories: coreCategories
                    )

                    if !optionalCategories.isEmpty {
                        questSection(
                            title: "Personal Only",
                            subtitle: "Optional — counts toward your personal XP only",
                            icon: "person.fill",
                            iconColor: Theme.textSecondary,
                            categories: optionalCategories
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .refreshable { await viewModel.load() }
            .overlay {
                if viewModel.isLoading && viewModel.categories.isEmpty {
                    LoadingView()
                }
            }

            if let reward = viewModel.lastReward {
                XPRewardOverlay(result: reward)
                    .onTapGesture { viewModel.lastReward = nil }
            }
        }
        .navigationTitle("Today")
        .task { await viewModel.load() }
        .safeAreaInset(edge: .bottom) {
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
    }

    private func questSection(
        title: String,
        subtitle: String,
        icon: String,
        iconColor: Color,
        categories: [CategoryStat]
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(iconColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.bottom, 2)

            VStack(spacing: 8) {
                ForEach(categories) { category in
                    let done = viewModel.isCompletedToday(category)
                    QuestCard(category: category, isDone: done) {
                        Task { await viewModel.complete(category.categoryId) }
                    }
                }
            }
        }
    }
}

private struct QuestCard: View {
    let category: CategoryStat
    let isDone: Bool
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isDone ? Theme.surfaceSecondary : category.categoryId.color)
                    .frame(width: 56, height: 56)
                Image(systemName: category.categoryId.systemImageName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(isDone ? Theme.textSecondary : Theme.ink)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(category.categoryId.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isDone ? Theme.textSecondary : Theme.textPrimary)
                HStack(spacing: 4) {
                    if !isDone && category.currentStreak > 0 {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.orange)
                    }
                    Text(isDone ? "Done today ✓" : "Streak: \(category.currentStreak) days")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Spacer()

            if isDone {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Theme.accentGreen)
            } else {
                Button(action: onComplete) {
                    Text("Log it")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(Theme.ink))
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(isDone ? 0.02 : 0.06), radius: 12, x: 0, y: 4)
        .opacity(isDone ? 0.7 : 1)
    }
}
