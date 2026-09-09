import SwiftUI

/// Dashboard — all XP/rank/streak values sourced from the server.
/// Nothing is computed or guessed client-side.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                header
                heroCard
                weekStrip
                questsSection
                achievementsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 36)
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

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: "E2E0DB"))
                    .frame(width: 46, height: 46)
                Text(String((viewModel.user?.username ?? "?").prefix(1)).uppercased())
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(Theme.ink)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Hello, \(viewModel.user?.username ?? "there")")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(Self.todayLabel)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            // Streak pill
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.orange)
                Text("\(viewModel.bestCurrentStreak)")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(width: 46, height: 46)
            .background(Theme.surface)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        let rank    = viewModel.user?.rank ?? .lowTierNormie1
        let totalXP = viewModel.user?.totalXP ?? 0
        let next    = rank.next

        let progress: Double = {
            guard let next else { return 1.0 }
            let span = max(next.xpRequired - rank.xpRequired, 1)
            return Double(min(max(totalXP - rank.xpRequired, 0), span)) / Double(span)
        }()

        // Use overlay approach so the decorative circles don't inflate the ZStack frame
        return RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(Color(hex: "1E1245"))
            .frame(height: 272)
            // Decorative blobs anchored to top-right
            .overlay(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "3D2299").opacity(0.85))
                        .frame(width: 200, height: 200)
                        .offset(x: 40, y: -55)
                    Circle()
                        .fill(Color(hex: "C2F542").opacity(0.18))
                        .frame(width: 110, height: 110)
                        .offset(x: 15, y: 55)
                }
                .clipped()
            }
            // Content anchored to bottom-left
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 14) {
                    // Rank badge
                    HStack(spacing: 5) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 10, weight: .black))
                        Text(rank.displayName.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .tracking(0.5)
                            .lineLimit(1)
                    }
                    .foregroundStyle(Color(hex: "1E1245"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "C2F542"))
                    .clipShape(Capsule())

                    // Big type
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Daily")
                            .font(.system(size: 46, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Goals")
                            .font(.system(size: 46, weight: .black, design: .rounded))
                            .foregroundStyle(Color(hex: "C2F542"))
                    }

                    // XP bar
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(totalXP) XP total")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.65))
                            Spacer()
                            if let next {
                                Text("→ \(next.displayName)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.45))
                                    .lineLimit(1)
                            } else {
                                Text("Max rank ✦")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color(hex: "C2F542"))
                            }
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.white.opacity(0.12)).frame(height: 6)
                                Capsule()
                                    .fill(Color(hex: "C2F542"))
                                    .frame(width: max(geo.size.width * CGFloat(progress), 8), height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                }
                .padding(24)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    // MARK: - Week Strip

    private var weekStrip: some View {
        let days = Self.currentWeek()
        let cal  = Calendar.current
        let today = cal.startOfDay(for: Date())

        return HStack(spacing: 0) {
            ForEach(days, id: \.self) { day in
                let isToday = cal.isDate(day, inSameDayAs: today)
                let num = cal.component(.day, from: day)
                let abbr = Self.dayAbbr(day)

                VStack(spacing: 6) {
                    Text(abbr)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isToday ? Theme.ink : Theme.textSecondary)

                    ZStack {
                        Circle()
                            .fill(isToday ? Theme.ink : Color.clear)
                            .frame(width: 34, height: 34)
                        Text("\(num)")
                            .font(.system(size: 14, weight: isToday ? .black : .regular))
                            .foregroundStyle(isToday ? .white : Theme.textPrimary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 3)
    }

    // MARK: - Quests (bento grid)

    private var questsSection: some View {
        // localCategoryIds is always the authoritative list of which categories
        // to show (required always included). API stats enrich cards with
        // streak/completion info when available.
        let ids = appState.localCategoryIds
        let statMap = Dictionary(uniqueKeysWithValues: viewModel.categories.map { ($0.categoryId, $0) })

        return VStack(alignment: .leading, spacing: 14) {
            Text("Today's Quests")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(Theme.textPrimary)

            mergedBentoGrid(ids, statMap: statMap)
        }
    }

    private func mergedBentoGrid(_ ids: [CategoryId], statMap: [CategoryId: CategoryStat]) -> some View {
        VStack(spacing: 12) {
            if let first = ids.first {
                let stat = statMap[first]
                NavigationLink {
                    CategoryDetailView(categoryId: first, initialStat: stat)
                } label: {
                    if let s = stat {
                        questCardLarge(s)
                    } else {
                        localCardLarge(first)
                    }
                }
                .buttonStyle(.plain)
            }
            let rest = ids.dropFirst()
            if !rest.isEmpty {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(Array(rest), id: \.id) { cat in
                        let stat = statMap[cat]
                        NavigationLink {
                            CategoryDetailView(categoryId: cat, initialStat: stat)
                        } label: {
                            if let s = stat {
                                questCardSmall(s)
                            } else {
                                localCardSmall(cat)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }


    private func questCardLarge(_ category: CategoryStat) -> some View {
        let done = viewModel.isCompletedToday(category)

        return ZStack(alignment: .bottomLeading) {
            // Background
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(done ? category.categoryId.color.opacity(0.35) : category.categoryId.color)

            // Watermark icon
            Image(systemName: category.categoryId.systemImageName)
                .font(.system(size: 110, weight: .black))
                .foregroundStyle(.black.opacity(0.07))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 10)
                .padding(.trailing, 10)
                .allowsHitTesting(false)

            // Labels
            VStack(alignment: .leading, spacing: 10) {
                // Status pill
                if done {
                    Label("Done today", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.ink.opacity(0.65))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.55))
                        .clipShape(Capsule())
                } else if category.currentStreak > 0 {
                    Label("\(category.currentStreak) day streak", systemImage: "flame.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.ink.opacity(0.65))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.orange, Theme.ink.opacity(0.65))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.55))
                        .clipShape(Capsule())
                }

                Text(category.categoryId.displayName)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .opacity(done ? 0.45 : 1)
            }
            .padding(22)
        }
        .frame(height: 172)
    }

    private func questCardSmall(_ category: CategoryStat) -> some View {
        let done = viewModel.isCompletedToday(category)

        return ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(done ? category.categoryId.color.opacity(0.35) : category.categoryId.color)

            Image(systemName: category.categoryId.systemImageName)
                .font(.system(size: 60, weight: .black))
                .foregroundStyle(.black.opacity(0.07))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 8)
                .padding(.trailing, 8)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 5) {
                if done {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Theme.ink.opacity(0.5))
                }
                Text(category.categoryId.displayName)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .opacity(done ? 0.45 : 1)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
        }
        .frame(height: 130)
    }

    // Local card variants (no CategoryStat, just CategoryId)
    private func localCardLarge(_ cat: CategoryId) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 26, style: .continuous).fill(cat.color)
            Image(systemName: cat.systemImageName)
                .font(.system(size: 110, weight: .black))
                .foregroundStyle(.black.opacity(0.07))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 10).padding(.trailing, 10)
                .allowsHitTesting(false)
            VStack(alignment: .leading, spacing: 6) {
                Text(cat.displayName)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("Tap to log")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.ink.opacity(0.5))
            }
            .padding(22)
        }
        .frame(height: 172)
    }

    private func localCardSmall(_ cat: CategoryId) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous).fill(cat.color)
            Image(systemName: cat.systemImageName)
                .font(.system(size: 60, weight: .black))
                .foregroundStyle(.black.opacity(0.07))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(8)
                .allowsHitTesting(false)
            Text(cat.displayName)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(14)
        }
        .frame(height: 130)
    }

    private var emptyQuestState: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Theme.surface)
                .frame(height: 130)
            VStack(spacing: 8) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.textSecondary)
                Text("No quests loaded")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    // MARK: - Achievements

    private var achievementsSection: some View {
        let unlockedCount = viewModel.achievements.filter(\.isUnlocked).count

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Achievements")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(unlockedCount)/\(viewModel.achievements.count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.achievements) { achievement in
                        VStack(spacing: 9) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(achievement.isUnlocked
                                          ? Color(hex: "FFE07A")
                                          : Theme.surface)
                                    .frame(width: 64, height: 64)
                                    .shadow(color: .black.opacity(achievement.isUnlocked ? 0.08 : 0.04),
                                            radius: 8, x: 0, y: 3)
                                Image(systemName: achievement.iconName)
                                    .font(.system(size: 26, weight: .semibold))
                                    .foregroundStyle(achievement.isUnlocked
                                                     ? Color(hex: "7A5C00")
                                                     : Theme.textSecondary)
                            }
                            .opacity(achievement.isUnlocked ? 1 : 0.38)

                            Text(achievement.title)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(width: 64)
                        }
                    }
                }
                .padding(.bottom, 4)
            }
        }
    }

    // MARK: - Helpers

    private static var todayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE d MMM."
        return f.string(from: Date())
    }

    private static func currentWeek() -> [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        guard let start = cal.date(byAdding: .day, value: -(weekday - 1), to: today) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    private static func dayAbbr(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return String(f.string(from: date).prefix(2))
    }
}