import SwiftUI

struct QuestsView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = QuestsViewModel()

    private var coreCategories: [CategoryStat] {
        viewModel.categories.filter { !$0.categoryId.isOptional }
    }

    // appState.localCategoryIds is the single source of truth for which optional
    // categories are enabled — same value HomeView uses, so both pages stay in sync.
    private var optionalCategories: [CategoryStat] {
        let enabledIds = Set(appState.localCategoryIds.filter(\.isOptional))
        return viewModel.categories.filter { enabledIds.contains($0.categoryId) }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                if viewModel.isLoading && viewModel.categories.isEmpty {
                    QuestsSkeletonView()
                } else {
                    VStack(spacing: 24) {
                        communitiesSection

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
            }
            .refreshable { await viewModel.load() }
        }
        .task {
            await viewModel.load()
            appState.completedTodayIds.formUnion(viewModel.categories.filter { viewModel.isCompletedToday($0) }.map(\.categoryId))
        }
        .navigationDestination(for: Community.self) { community in
            CommunityDetailView(communityId: community.communityId, initialName: community.name)
        }
        .navigationDestination(for: CommunityGoalNavigationTarget.self) { target in
            CommunityGoalFeedView(communityId: target.communityId, goal: target.goal)
        }
        .navigationDestination(for: CommunitySettingsNavigationTarget.self) { target in
            CommunitySettingsView(communityId: target.communityId)
        }
        .navigationDestination(for: UserProfileNavigationTarget.self) { target in
            UserProfileView(sub: target.sub, initialUsername: target.initialUsername)
        }
        .navigationDestination(for: ShowMyCommunityList.self) { _ in
            MyCommunityListView()
        }
        .onAppear {
            if !viewModel.categories.isEmpty {
                Task {
                    await viewModel.load()
                    appState.completedTodayIds.formUnion(viewModel.categories.filter { viewModel.isCompletedToday($0) }.map(\.categoryId))
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Communities

    @ViewBuilder
    private var communitiesSection: some View {
        if viewModel.communities.isEmpty {
            NavigationLink(value: ShowMyCommunityList()) {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Theme.accent.opacity(0.18))
                            .frame(width: 44, height: 44)
                        Image(systemName: "person.3.fill")
                            .font(Theme.font(19, .regular))
                            .foregroundStyle(Theme.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Join or create your first community")
                            .font(Theme.font(15, .regular))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Compete with friends on shared goals")
                            .font(Theme.font(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(Theme.font(13, .regular))
                        .foregroundStyle(Theme.textSecondary.opacity(0.5))
                }
                .padding(14)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.accent)
                    Text("My Communities")
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    NavigationLink("See All", value: ShowMyCommunityList())
                        .font(Theme.font(12, .regular))
                        .foregroundStyle(Theme.textSecondary)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.communities) { community in
                            // NavigationLink(value:) + .navigationDestination(for:) -
                            // NavigationLink(destination:) eagerly reconstructs its
                            // destination (and the destination's own @State) on every
                            // re-render of this row, which for a stateful destination
                            // like CommunityDetailView causes a runaway reconstruction
                            // loop that pegs the CPU and can prevent the view from ever
                            // finishing its real load.
                            NavigationLink(value: community) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Image(systemName: "person.3.fill")
                                        .font(Theme.font(17))
                                        .foregroundStyle(Theme.accent)
                                    Text(community.name)
                                        .font(Theme.font(14, .regular))
                                        .foregroundStyle(Theme.textPrimary)
                                        .lineLimit(1)
                                    Text("\(community.memberCount ?? 0) members")
                                        .font(Theme.font(11))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                .padding(14)
                                .frame(width: 150, alignment: .leading)
                                .background(Theme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
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
                    .font(Theme.font(13))
                    .foregroundStyle(iconColor)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(Theme.font(14))
                        .foregroundStyle(Theme.textPrimary)
                    Text(subtitle)
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.bottom, 2)

            VStack(spacing: 8) {
                ForEach(categories) { category in
                    let done = appState.completedTodayIds.contains(category.categoryId)
                    NavigationLink {
                        CategoryDetailView(
                            categoryId: category.categoryId,
                            initialStat: category,
                            onComplete: { Task { await viewModel.load() } }
                        )
                    } label: {
                        QuestCard(category: category, isDone: done)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct QuestCard: View {
    let category: CategoryStat
    let isDone: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isDone ? Theme.surfaceSecondary : category.categoryId.color)
                    .frame(width: 46, height: 46)
                Image(systemName: category.categoryId.systemImageName)
                    .font(Theme.font(20, .regular))
                    .foregroundStyle(isDone ? Theme.textSecondary : Theme.ink)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(category.categoryId.displayName)
                    .font(Theme.font(15, .regular))
                    .foregroundStyle(isDone ? Theme.textSecondary : Theme.textPrimary)
                HStack(spacing: 4) {
                    if !isDone && category.currentStreak > 0 {
                        Image(systemName: "flame.fill")
                            .font(Theme.font(10))
                            .foregroundStyle(Theme.accent)
                    }
                    Text(isDone ? "Done today ✓" : "Streak: \(category.currentStreak) days")
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Spacer()

            if isDone {
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Theme.font(25))
                        .foregroundStyle(Theme.accentGreen)
                    if let xp = category.categoryXPToday, xp > 0 {
                        Text("+\(xp) XP")
                            .font(Theme.font(11))
                            .foregroundStyle(Theme.accentGreen)
                    }
                }
            } else {
                HStack(spacing: 4) {
                    Text("Log it")
                        .font(Theme.font(13, .regular))
                        .foregroundStyle(Theme.accent)
                    Image(systemName: "chevron.right")
                        .font(Theme.font(11))
                        .foregroundStyle(Theme.accent.opacity(0.7))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(Theme.accent.opacity(0.12)))
            }
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(isDone ? 0.02 : 0.05), radius: 8, x: 0, y: 3)
        .opacity(isDone ? 0.7 : 1)
    }
}
