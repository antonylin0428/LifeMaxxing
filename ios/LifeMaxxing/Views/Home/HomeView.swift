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

    private var headerInitialsCircle: some View {
        ZStack {
            Circle()
                .fill(Theme.surfaceSecondary)
                .frame(width: 46, height: 46)
            Text(String((viewModel.user?.username ?? "?").prefix(1)).uppercased())
                .font(Theme.font(19))
                .foregroundStyle(Theme.ink)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            // Avatar
            Group {
                if let urlString = viewModel.user?.avatarUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable()
                                .scaledToFill()
                                .frame(width: 46, height: 46)
                                .clipShape(Circle())
                        default:
                            headerInitialsCircle
                        }
                    }
                } else {
                    headerInitialsCircle
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Hello, \(viewModel.user?.username ?? "there")")
                    .font(Theme.font(15))
                    .foregroundStyle(Theme.textPrimary)
                Text(Self.todayLabel)
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.leading, 10)

            Spacer()

            // Streak pill
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.accent)
                Text("\(viewModel.bestCurrentStreak)")
                    .font(Theme.font(14))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(width: 46, height: 46)
            .background(Theme.accent.opacity(0.12))
            .clipShape(Circle())
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

        return ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.surface)

            // Mountain illustration (top-right)
            GeometryReader { geo in
                ZStack(alignment: .topTrailing) {
                    // Sun
                    Circle()
                        .fill(Theme.accent.opacity(0.28))
                        .frame(width: 70, height: 70)
                        .offset(x: -20, y: 18)

                    // Mountain canvas
                    Canvas { ctx, size in
                        var far = Path()
                        far.move(to: CGPoint(x: 0, y: size.height))
                        far.addLine(to: CGPoint(x: size.width * 0.28, y: size.height * 0.30))
                        far.addLine(to: CGPoint(x: size.width * 0.55, y: size.height * 0.54))
                        far.addLine(to: CGPoint(x: size.width * 0.78, y: size.height * 0.28))
                        far.addLine(to: CGPoint(x: size.width, y: size.height * 0.52))
                        far.addLine(to: CGPoint(x: size.width, y: size.height))
                        far.closeSubpath()
                        ctx.fill(far, with: .color(.black.opacity(0.04)))
                        ctx.stroke(far, with: .color(.black.opacity(0.09)), lineWidth: 1.2)

                        var near = Path()
                        near.move(to: CGPoint(x: 0, y: size.height))
                        near.addLine(to: CGPoint(x: size.width * 0.35, y: size.height * 0.55))
                        near.addLine(to: CGPoint(x: size.width * 0.6, y: size.height * 0.72))
                        near.addLine(to: CGPoint(x: size.width, y: size.height * 0.62))
                        near.addLine(to: CGPoint(x: size.width, y: size.height))
                        near.closeSubpath()
                        ctx.fill(near, with: .color(Color(hex: "E8916A").opacity(0.10)))
                    }
                    .frame(width: geo.size.width * 0.62, height: 114)
                    .offset(y: geo.size.height - 114)
                }
            }
            .allowsHitTesting(false)

            // Content
            VStack(alignment: .leading, spacing: 14) {
                // Rank badge
                HStack(spacing: 5) {
                    Image(systemName: "trophy.fill")
                        .font(Theme.font(11, .regular))
                    Text(rank.displayName.uppercased())
                        .font(Theme.font(11))
                        .tracking(0.4)
                        .lineLimit(1)
                }
                .foregroundStyle(Color(hex: "7A3C10"))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.accent.opacity(0.18))
                .clipShape(Capsule())

                // Title
                Text("Daily Goals")
                    .font(Theme.font(33))
                    .foregroundStyle(Theme.textPrimary)

                // XP bar
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text("\(totalXP) XP total")
                            .font(Theme.font(12))
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        if let next {
                            HStack(spacing: 3) {
                                Text("→").foregroundStyle(Theme.accent)
                                Text(next.displayName).foregroundStyle(Theme.textSecondary)
                            }
                            .font(Theme.font(12))
                            .lineLimit(1)
                        } else {
                            Text("Max rank ✦")
                                .font(Theme.font(12))
                                .foregroundStyle(Theme.accent)
                        }
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.surfaceSecondary).frame(height: 6)
                            Capsule()
                                .fill(Theme.accent)
                                .frame(width: max(geo.size.width * CGFloat(progress), 8), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
            .padding(24)
        }
        .frame(height: 252)
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 5)
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
                        .font(Theme.font(12, .regular))
                        .foregroundStyle(isToday ? Theme.accent : Theme.textSecondary)

                    ZStack {
                        Circle()
                            .fill(isToday ? Theme.accent : Color.clear)
                            .frame(width: 34, height: 34)
                        Text("\(num)")
                            .font(.system(size: 14, weight: isToday ? .bold : .regular))
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
            HStack {
                Text("Today's Quests")
                    .font(Theme.font(17))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }
            .overlay(alignment: .bottomLeading) {
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 32, height: 2)
                    .offset(y: 4)
            }

            mergedBentoGrid(ids, statMap: statMap)
        }
        .padding(.top, 4)
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

        return HStack(spacing: 0) {
            // Left content
            VStack(alignment: .leading, spacing: 8) {
                // Status pill
                if done {
                    Label("Done today", systemImage: "checkmark.circle.fill")
                        .font(Theme.font(12, .regular))
                        .foregroundStyle(Theme.ink.opacity(0.6))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.55))
                        .clipShape(Capsule())
                } else if category.currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(Theme.accent)
                        Text("\(category.currentStreak) day streak")
                    }
                    .font(Theme.font(12, .regular))
                    .foregroundStyle(Theme.ink.opacity(0.6))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.55))
                    .clipShape(Capsule())
                }

                Text(category.categoryId.displayName)
                    .font(Theme.font(23))
                    .foregroundStyle(Theme.ink)
                    .opacity(done ? 0.5 : 1)

                Text(shortPrompt(category.categoryId))
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.ink.opacity(0.55))
                    .lineLimit(2)
            }
            .padding(16)

            Spacer()

            // Right: icon + arrow
            VStack(alignment: .trailing, spacing: 8) {
                Image(systemName: category.categoryId.systemImageName)
                    .font(Theme.font(39, .regular))
                    .foregroundStyle(.black.opacity(0.12))

                ZStack {
                    Circle()
                        .fill(.white.opacity(0.65))
                        .frame(width: 30, height: 30)
                    Image(systemName: done ? "checkmark" : "arrow.right")
                        .font(Theme.font(12, .regular))
                        .foregroundStyle(Theme.ink.opacity(0.6))
                }
            }
            .padding(.trailing, 16)
            .padding(.vertical, 16)
        }
        .frame(height: 140)
        .background(done ? category.categoryId.color.opacity(0.4) : category.categoryId.color)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func shortPrompt(_ cat: CategoryId) -> String {
        switch cat {
        case .fitness:          return "Complete your workout for today."
        case .screenDiscipline: return "Stay off social media and be present."
        case .focus:            return "Put in deep, focused work or study."
        case .personalGoals:    return "Make progress on one personal goal."
        case .reflection:       return "Journal, meditate, or reflect today."
        case .spiritual:        return "Engage in prayer or spiritual practice."
        }
    }

    private func questCardSmall(_ category: CategoryStat) -> some View {
        let done = viewModel.isCompletedToday(category)

        return ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(done ? category.categoryId.color.opacity(0.4) : category.categoryId.color)

            Image(systemName: category.categoryId.systemImageName)
                .font(Theme.font(41, .regular))
                .foregroundStyle(.black.opacity(0.10))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, 10)
                .padding(.trailing, 10)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 4) {
                if done {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Theme.font(14, .regular))
                        .foregroundStyle(Theme.ink.opacity(0.45))
                }
                Text(category.categoryId.displayName)
                    .font(Theme.font(15))
                    .foregroundStyle(Theme.ink)
                    .opacity(done ? 0.5 : 1)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
        }
        .frame(height: 114)
    }

    // Local card variants (no CategoryStat, just CategoryId)
    private func localCardLarge(_ cat: CategoryId) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(cat.displayName)
                    .font(Theme.font(23))
                    .foregroundStyle(Theme.ink)
                Text(shortPrompt(cat))
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.ink.opacity(0.55))
                    .lineLimit(2)
            }
            .padding(16)
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Image(systemName: cat.systemImageName)
                    .font(Theme.font(39, .regular))
                    .foregroundStyle(.black.opacity(0.12))
                ZStack {
                    Circle().fill(.white.opacity(0.65)).frame(width: 30, height: 30)
                    Image(systemName: "arrow.right")
                        .font(Theme.font(12, .regular))
                        .foregroundStyle(Theme.ink.opacity(0.6))
                }
            }
            .padding(.trailing, 16).padding(.vertical, 16)
        }
        .frame(height: 140)
        .background(cat.color)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func localCardSmall(_ cat: CategoryId) -> some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 22, style: .continuous).fill(cat.color)
            Image(systemName: cat.systemImageName)
                .font(Theme.font(41, .regular))
                .foregroundStyle(.black.opacity(0.10))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(10)
                .allowsHitTesting(false)
            Text(cat.displayName)
                .font(Theme.font(15))
                .foregroundStyle(Theme.ink)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
        }
        .frame(height: 114)
    }

    private var emptyQuestState: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Theme.surface)
                .frame(height: 130)
            VStack(spacing: 8) {
                Image(systemName: "moon.zzz.fill")
                    .font(Theme.font(29))
                    .foregroundStyle(Theme.textSecondary)
                Text("No quests loaded")
                    .font(Theme.font(16, .regular))
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
                    .font(Theme.font(17))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(unlockedCount)/\(viewModel.achievements.count)")
                    .font(Theme.font(12, .regular))
                    .foregroundStyle(Theme.textSecondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.achievements) { achievement in
                        VStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(achievement.isUnlocked
                                          ? Color(hex: "FFE07A")
                                          : Theme.surface)
                                    .frame(width: 52, height: 52)
                                    .shadow(color: .black.opacity(achievement.isUnlocked ? 0.07 : 0.03),
                                            radius: 6, x: 0, y: 2)
                                Image(systemName: achievement.iconName)
                                    .font(Theme.font(21, .regular))
                                    .foregroundStyle(achievement.isUnlocked
                                                     ? Color(hex: "7A5C00")
                                                     : Theme.textSecondary)
                            }
                            .opacity(achievement.isUnlocked ? 1 : 0.38)

                            Text(achievement.title)
                                .font(Theme.font(10, .regular))
                                .foregroundStyle(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(width: 52)
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