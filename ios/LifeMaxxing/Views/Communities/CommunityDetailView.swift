import SwiftUI
import PhotosUI

struct CommunityDetailView: View {
    let communityId: String
    var initialName: String? = nil

    @State private var viewModel: CommunityViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showInviteSheet = false
    @Environment(\.dismiss) private var dismiss

    // Same cycling pastel vocabulary as CategoryId+UI.swift, reused here for
    // avatar fallbacks and per-goal icon badges instead of a flat neutral tint.
    private let pastelPalette: [Color] = [
        Color(hex: "F7C8A8"), Color(hex: "B4C8E0"), Color(hex: "C0B8E0"),
        Color(hex: "B4D4A8"), Color(hex: "E0B4C4"), Color(hex: "E8D4A8"),
    ]

    init(communityId: String, initialName: String? = nil) {
        self.communityId = communityId
        self.initialName = initialName
        _viewModel = State(initialValue: CommunityViewModel(communityId: communityId))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if viewModel.isLoading && viewModel.community == nil {
                ScrollView { CommunityListSkeletonView() }
            } else {
                content
            }
        }
        .navigationTitle("Group")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    circleIcon("chevron.left")
                }
            }
            if viewModel.isMember {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showInviteSheet = true } label: {
                        circleIcon("person.badge.plus")
                    }
                }
            }
            if viewModel.isCreator {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(value: CommunitySettingsNavigationTarget(communityId: communityId)) {
                        circleIcon("gearshape")
                    }
                }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .onChange(of: selectedPhotoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    await viewModel.uploadPhoto(data)
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showInviteSheet) {
            if let community = viewModel.community {
                InviteToCommunitySheet(
                    community: community,
                    isCreator: viewModel.isCreator,
                    viewModel: viewModel
                ) { showInviteSheet = false }
            }
        }
    }

    private func circleIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(Theme.font(15, .regular))
            .foregroundStyle(Theme.textPrimary)
            .frame(width: 34, height: 34)
            .background(Theme.surface)
            .clipShape(Circle())
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let community = viewModel.community {
                    communityHeader(community: community)
                }

                if !viewModel.isMember {
                    joinButton
                } else {
                    goalsSection
                }

                if !viewModel.leaderboard.isEmpty {
                    leaderboardSection
                }
            }
            .padding(20)
        }
    }

    // MARK: - Community Header

    private func communityHeader(community: Community) -> some View {
        let done = viewModel.goals.filter { $0.myCompletion != nil }.count
        let total = viewModel.goals.count

        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(Theme.font(10, .semibold))
                Text("\(community.memberCount ?? viewModel.leaderboard.count) MEMBERS")
                    .font(Theme.font(11, .semibold))
                    .tracking(0.4)
            }
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Theme.accent.opacity(0.15))
            .clipShape(Capsule())

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(community.name)
                        .font(Theme.font(22))
                        .foregroundStyle(Theme.textPrimary)
                    Text(headerSubtitle(community))
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
                if viewModel.isMember && total > 0 {
                    progressRing(done: done, total: total)
                }
            }

            if !viewModel.leaderboard.isEmpty {
                avatarsRow
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    private func headerSubtitle(_ community: Community) -> String {
        if let desc = community.description, !desc.isEmpty {
            return "\(desc) · by \(community.createdByUsername)"
        }
        return "Created by \(community.createdByUsername)"
    }

    private func progressRing(done: Int, total: Int) -> some View {
        ZStack {
            Circle()
                .stroke(Theme.surfaceSecondary, lineWidth: 5)
            Circle()
                .trim(from: 0, to: total > 0 ? min(CGFloat(done) / CGFloat(total), 1) : 0)
                .stroke(Theme.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(done)/\(total)")
                    .font(Theme.font(14, .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("today")
                    .font(Theme.font(9))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(width: 60, height: 60)
    }

    private var avatarsRow: some View {
        HStack(spacing: 6) {
            ForEach(Array(viewModel.leaderboard.prefix(6).enumerated()), id: \.element.id) { index, entry in
                ZStack {
                    Circle()
                        .fill(pastelPalette[index % pastelPalette.count].opacity(0.75))
                        .frame(width: 28, height: 28)
                    Text(String(entry.username.prefix(1)).uppercased())
                        .font(Theme.font(12, .semibold))
                        .foregroundStyle(Theme.ink)
                }
            }
            if viewModel.leaderboard.count > 6 {
                ZStack {
                    Circle().fill(Theme.surfaceSecondary).frame(width: 28, height: 28)
                    Text("+\(viewModel.leaderboard.count - 6)")
                        .font(Theme.font(10, .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    // MARK: - Join

    private var joinButton: some View {
        Button {
            Task { await viewModel.join() }
        } label: {
            if viewModel.isJoining {
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle().fill(Color.white.opacity(0.8)).frame(width: 6, height: 6)
                    }
                }
            } else {
                Text("Join Community")
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(viewModel.isJoining)
    }

    // MARK: - Goals

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Goals")
                    .font(Theme.font(17))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(todayDateString)
                    .font(Theme.font(13))
                    .foregroundStyle(Theme.textSecondary)
            }
            .overlay(alignment: .bottomLeading) {
                Rectangle()
                    .fill(Theme.accent)
                    .frame(width: 32, height: 2)
                    .offset(y: 4)
            }
            .padding(.bottom, 4)

            if viewModel.isLoading && viewModel.goals.isEmpty {
                // isLoading stays true until goals (and feed) finish fetching
                // too, not just the community/leaderboard - without this,
                // "No goals set up yet" flashes before real goals arrive.
                goalsLoadingSkeleton
            } else if viewModel.goals.isEmpty {
                noGoalsPlaceholder
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(viewModel.goals.enumerated()), id: \.element.id) { index, goal in
                        // NavigationLink(value:) pushing a bundled target, resolved by a
                        // navigationDestination(for:) registered up at the tab root (see
                        // QuestsView/MyCommunityListView), not here - see
                        // CommunityGoalNavigationTarget's doc comment for why.
                        NavigationLink(value: CommunityGoalNavigationTarget(communityId: communityId, goal: goal)) {
                            goalCard(goal: goal, color: pastelPalette[index % pastelPalette.count])
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var todayDateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE d MMM."
        return f.string(from: Date())
    }

    private var goalsLoadingSkeleton: some View {
        VStack(spacing: 10) {
            ForEach(0..<2, id: \.self) { _ in
                HStack(spacing: 14) {
                    SkeletonCircle(size: 46)
                    VStack(alignment: .leading, spacing: 5) {
                        SkeletonBox(width: 120, height: 14)
                        SkeletonBox(width: 150, height: 11)
                    }
                    Spacer()
                    SkeletonCircle(size: 32)
                }
                .padding(14)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
            }
        }
    }

    private var noGoalsPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "target")
                .font(Theme.font(33))
                .foregroundStyle(Theme.textSecondary.opacity(0.4))
            Text("No goals set up yet")
                .font(Theme.font(15))
                .foregroundStyle(Theme.textSecondary)
            if viewModel.isCreator {
                NavigationLink(value: CommunitySettingsNavigationTarget(communityId: communityId)) {
                    Text("Add Goals →")
                        .font(Theme.font(14, .regular))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func goalCard(goal: CommunityGoal, color: Color) -> some View {
        let isDone = goal.myCompletion != nil

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isDone ? Theme.accent : color.opacity(0.75))
                    .frame(width: 46, height: 46)
                Image(systemName: goal.icon)
                    .font(Theme.font(19, .regular))
                    .foregroundStyle(isDone ? .white : Theme.ink)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(goal.name)
                    .font(Theme.font(16, .regular))
                    .foregroundStyle(Theme.textPrimary)
                Text(goalSubtitle(goal))
                    .font(Theme.font(12))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if isDone {
                VStack(spacing: 3) {
                    ZStack {
                        Circle().fill(Theme.accent).frame(width: 28, height: 28)
                        Image(systemName: "checkmark")
                            .font(Theme.font(12, .semibold))
                            .foregroundStyle(.white)
                    }
                    Text("Done")
                        .font(Theme.font(10, .regular))
                        .foregroundStyle(Theme.accent)
                }
            } else {
                ZStack {
                    Circle().fill(Theme.accent.opacity(0.15)).frame(width: 32, height: 32)
                    Image(systemName: "arrow.right")
                        .font(Theme.font(13, .semibold))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .padding(14)
        .background(isDone ? Theme.accent.opacity(0.12) : Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    private func goalSubtitle(_ goal: CommunityGoal) -> String {
        if let desc = goal.description, !desc.isEmpty {
            return "\(goal.trackingType.displayName) · \(desc)"
        }
        return goal.trackingType.displayName
    }

    // MARK: - Leaderboard

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Leaderboard")
                .font(Theme.font(17))
                .foregroundStyle(Theme.textPrimary)
                .overlay(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(Theme.accent)
                        .frame(width: 32, height: 2)
                        .offset(y: 4)
                }
                .padding(.bottom, 4)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.leaderboard.enumerated()), id: \.element.id) { index, entry in
                    leaderboardRow(entry: entry, rank: index + 1, maxXP: maxLeaderboardXP)
                    if index < viewModel.leaderboard.count - 1 {
                        Divider().padding(.horizontal, 16)
                    }
                }
            }
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        }
    }

    private var maxLeaderboardXP: Int {
        viewModel.leaderboard.map(\.totalXP).max() ?? 0
    }

    private func leaderboardRow(entry: CommunityLeaderboardEntry, rank: Int, maxXP: Int) -> some View {
        let ratio: CGFloat = maxXP > 0 ? min(CGFloat(entry.totalXP) / CGFloat(maxXP), 1) : 0

        let rowContent = VStack(spacing: 8) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Theme.accent.opacity(0.15)).frame(width: 28, height: 28)
                    Text("\(rank)")
                        .font(Theme.font(13, .semibold))
                        .foregroundStyle(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(entry.username)
                            .font(.system(size: 14, weight: entry.isMe ? .bold : .medium))
                            .foregroundStyle(Theme.textPrimary)
                        if entry.isMe {
                            Text("you")
                                .font(Theme.font(11, .regular))
                                .foregroundStyle(Theme.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Theme.accent.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                    if let rank = entry.rank {
                        Text(rank.displayName)
                            .font(Theme.font(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Spacer()
                Text("\(entry.totalXP) XP")
                    .font(Theme.font(14, .regular))
                    .foregroundStyle(Theme.textSecondary)
            }

            // A GeometryReader here (reading width to size the fill capsule)
            // sits inside a VStack with no explicit width of its own - that's
            // a classic SwiftUI layout feedback loop (GeometryReader wants all
            // available width, its parent wants to size to content) that
            // never converges and pegs the main thread forever. scaleEffect
            // achieves the same fill visually without participating in layout.
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.surfaceSecondary)
                    .frame(height: 4)
                Capsule()
                    .fill(Theme.accent)
                    .frame(height: 4)
                    .scaleEffect(x: ratio, y: 1, anchor: .leading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)

        if entry.isMe {
            return AnyView(rowContent)
        } else {
            return AnyView(
                NavigationLink(value: UserProfileNavigationTarget(sub: entry.sub, initialUsername: entry.username)) {
                    rowContent
                }
                .buttonStyle(.plain)
            )
        }
    }
}
