import SwiftUI

struct CommunityDetailView: View {
    let communityId: String
    var initialName: String? = nil

    @State private var viewModel: CommunityViewModel

    init(communityId: String, initialName: String? = nil) {
        self.communityId = communityId
        self.initialName = initialName
        _viewModel = State(initialValue: CommunityViewModel(communityId: communityId))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if viewModel.isLoading && viewModel.community == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                content
            }
        }
        .navigationTitle(viewModel.community?.name ?? initialName ?? "Community")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header card
                if let community = viewModel.community {
                    communityHeader(community: community)
                }

                // Join button (shown if not a member)
                if !viewModel.isMember {
                    Button {
                        Task { await viewModel.join() }
                    } label: {
                        if viewModel.isJoining {
                            ProgressView().tint(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Theme.accentGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        } else {
                            Text("Join Community")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Theme.accentGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .disabled(viewModel.isJoining)
                }

                // Leaderboard
                if !viewModel.leaderboard.isEmpty {
                    leaderboardSection
                }
            }
            .padding(20)
        }
    }

    private func communityHeader(community: Community) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: "C5B5F5").opacity(0.3))
                        .frame(width: 52, height: 52)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color(hex: "7A5CF5"))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(community.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Created by \(community.createdByUsername)")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(community.memberCount ?? viewModel.leaderboard.count)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text("members")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            if let desc = community.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Leaderboard")
                .font(.system(size: 16, weight: .semibold))
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
        HStack(spacing: 14) {
            // Rank number
            Text("\(rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(rank <= 3 ? Color(hex: "F5A623") : Theme.textSecondary)
                .frame(width: 24, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.username)
                        .font(.system(size: 14, weight: entry.isMe ? .bold : .medium))
                        .foregroundStyle(Theme.textPrimary)
                    if entry.isMe {
                        Text("you")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Theme.accentGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.accentGreen.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                if let rank = entry.rank {
                    Text(rank.rawValue)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            Text("\(entry.totalXP) XP")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(entry.isMe ? Theme.accentGreen.opacity(0.05) : Color.clear)
    }
}
