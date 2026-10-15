import SwiftUI
import PhotosUI

struct CommunityDetailView: View {
    let communityId: String
    var initialName: String? = nil

    @State private var viewModel: CommunityViewModel
    @State private var selectedPhotoItem: PhotosPickerItem?

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
        .navigationTitle(viewModel.community?.name ?? initialName ?? "Community")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.isCreator {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: CommunitySettingsView(communityId: communityId)) {
                        Image(systemName: "gearshape")
                            .font(Theme.font(17, .regular))
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
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
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

    // MARK: - Goals

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Goals")
                .font(Theme.font(14))
                .foregroundStyle(Theme.textSecondary)
                .textCase(.uppercase)
                .tracking(0.8)

            if viewModel.goals.isEmpty {
                noGoalsPlaceholder
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.goals) { goal in
                        NavigationLink(destination: CommunityGoalFeedView(
                            communityId: communityId, goal: goal)) {
                            goalCard(goal: goal)
                        }
                        .buttonStyle(.plain)
                    }
                }
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
                NavigationLink(destination: CommunitySettingsView(communityId: communityId)) {
                    Text("Add Goals →")
                        .font(Theme.font(14, .regular))
                        .foregroundStyle(Theme.accentGreen)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func goalCard(goal: CommunityGoal) -> some View {
        HStack(spacing: 14) {
            Text(goal.emoji)
                .font(Theme.font(29))
                .frame(width: 48, height: 48)
                .background(Theme.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.name)
                    .font(Theme.font(16, .regular))
                    .foregroundStyle(Theme.textPrimary)
                if let desc = goal.description, !desc.isEmpty {
                    Text(desc)
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }
                HStack(spacing: 4) {
                    Image(systemName: goal.trackingType == .photo ? "camera.fill"
                          : goal.trackingType == .text ? "text.bubble.fill" : "camera.badge.plus")
                        .font(Theme.font(11))
                        .foregroundStyle(Theme.textSecondary)
                    Text(goal.trackingType.displayName)
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }

            Spacer()

            if let completion = goal.myCompletion {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Theme.font(23))
                        .foregroundStyle(Theme.accentGreen)
                    Text("Done")
                        .font(Theme.font(11, .regular))
                        .foregroundStyle(Theme.accentGreen)
                }
            } else {
                Image(systemName: "chevron.right")
                    .font(Theme.font(14, .regular))
                    .foregroundStyle(Theme.textSecondary.opacity(0.4))
            }
        }
        .padding(14)
        .background(goal.myCompletion != nil
                    ? Theme.accentGreen.opacity(0.05)
                    : Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(goal.myCompletion != nil ? Theme.accentGreen.opacity(0.25) : Color.clear, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    // MARK: - Join

    private var joinButton: some View {
        Button {
            Task { await viewModel.join() }
        } label: {
            Group {
                if viewModel.isJoining {
                    HStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle().fill(Color.white.opacity(0.8)).frame(width: 6, height: 6)
                        }
                    }
                } else {
                    Text("Join Community")
                        .font(Theme.font(17, .regular))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Theme.accentGreen)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(viewModel.isJoining)
    }

    // MARK: - Community Header

    private func communityHeader(community: Community) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: "C5B5F5").opacity(0.3))
                        .frame(width: 52, height: 52)
                    Image(systemName: "person.3.fill")
                        .font(Theme.font(23, .regular))
                        .foregroundStyle(Color(hex: "7A5CF5"))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(community.name)
                        .font(Theme.font(21))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Created by \(community.createdByUsername)")
                        .font(Theme.font(13))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(community.memberCount ?? viewModel.leaderboard.count)")
                        .font(Theme.font(21))
                        .foregroundStyle(Theme.textPrimary)
                    Text("members")
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            if let desc = community.description, !desc.isEmpty {
                Text(desc)
                    .font(Theme.font(15))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    // MARK: - Leaderboard

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Leaderboard")
                .font(Theme.font(17, .regular))
                .foregroundStyle(Theme.textPrimary)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.leaderboard.enumerated()), id: \.element.id) { index, entry in
                    leaderboardRow(entry: entry, rank: index + 1)
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

    private func leaderboardRow(entry: CommunityLeaderboardEntry, rank: Int) -> some View {
        let rowContent = HStack(spacing: 14) {
            Text("\(rank)")
                .font(Theme.font(15))
                .foregroundStyle(rank <= 3 ? Color(hex: "F5A623") : Theme.textSecondary)
                .frame(width: 24, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.username)
                        .font(.system(size: 14, weight: entry.isMe ? .bold : .medium))
                        .foregroundStyle(Theme.textPrimary)
                    if entry.isMe {
                        Text("you")
                            .font(Theme.font(11, .regular))
                            .foregroundStyle(Theme.accentGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accentGreen.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                if let rank = entry.rank {
                    Text(rank.rawValue)
                        .font(Theme.font(12))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            Text("\(entry.totalXP) XP")
                .font(Theme.font(14, .regular))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(entry.isMe ? Theme.accentGreen.opacity(0.05) : Color.clear)

        if entry.isMe {
            return AnyView(rowContent)
        } else {
            return AnyView(
                NavigationLink(destination: UserProfileView(sub: entry.sub, initialUsername: entry.username)) {
                    rowContent
                }
                .buttonStyle(.plain)
            )
        }
    }
}
