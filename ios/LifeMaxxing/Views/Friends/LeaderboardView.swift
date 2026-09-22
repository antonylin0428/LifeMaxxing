import SwiftUI

struct LeaderboardView: View {
    @State private var viewModel = LeaderboardViewModel()
    @State private var feedPosts: [FeedPost] = []
    @State private var isFeedLoading = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Leaderboard section
                    sectionHeader("Leaderboard")
                    VStack(spacing: 8) {
                        ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                            leaderboardRow(rank: index + 1, entry: entry)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)

                    // Community Feed section
                    sectionHeader("Community Feed")
                    communityFeed
                        .padding(.horizontal, 20)
                        .padding(.bottom, 36)
                }
                .padding(.top, 8)
            }
            .refreshable {
                await viewModel.load()
                await loadFeed()
            }
            .overlay {
                if viewModel.isLoading && viewModel.entries.isEmpty { LoadingView() }
            }
        }
        .navigationTitle("Leaderboard")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink { FriendsListView() } label: {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .task {
            await viewModel.load()
            await loadFeed()
        }
        .safeAreaInset(edge: .bottom) {
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Theme.textSecondary)
            .textCase(.uppercase)
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
    }

    @ViewBuilder
    private var communityFeed: some View {
        if isFeedLoading && feedPosts.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
        } else if feedPosts.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 36))
                    .foregroundStyle(Theme.textSecondary.opacity(0.5))
                Text("No gym posts yet — be the first!")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else {
            VStack(spacing: 16) {
                ForEach(feedPosts) { post in
                    feedCard(post)
                }
            }
        }
    }

    private func feedCard(_ post: FeedPost) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            AsyncImage(url: URL(string: post.photoUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipped()
                case .failure:
                    Color(hex: "E8E8E4")
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundStyle(Theme.textSecondary)
                        )
                default:
                    Color(hex: "E8E8E4")
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .overlay(ProgressView())
                }
            }
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 16, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 16,
                style: .continuous
            ))

            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: "E8E8E4"))
                    .frame(width: 38, height: 38)
                    .overlay(
                        Text(String(post.username.prefix(1)).uppercased())
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.ink)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(post.username)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                    HStack(spacing: 6) {
                        if post.currentStreak > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.orange)
                                Text("\(post.currentStreak)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        Text(timeAgo(post.completedAt))
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer()

                Text("+\(post.xpAwarded) XP")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Theme.ink)
                    .clipShape(Capsule())
            }
            .padding(14)
            .background(Theme.surface)
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 0, bottomLeadingRadius: 16,
                bottomTrailingRadius: 16, topTrailingRadius: 0,
                style: .continuous
            ))
        }
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    private func timeAgo(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) else {
            return ""
        }
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds / 60)m ago" }
        if seconds < 86400 { return "\(seconds / 3600)h ago" }
        return "\(seconds / 86400)d ago"
    }

    private func loadFeed() async {
        isFeedLoading = true
        defer { isFeedLoading = false }
        if let posts = try? await FeedAPI.shared.getFriendsFeed() {
            feedPosts = posts
        }
    }

    private func leaderboardRow(rank: Int, entry: LeaderboardEntry) -> some View {
        let rowContent = HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(rankBadgeColor(rank: rank))
                    .frame(width: 36, height: 36)
                Text("#\(rank)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(rank <= 3 ? .white : Theme.textSecondary)
            }

            Circle()
                .fill(Color(hex: "E8E8E4"))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(entry.username.prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.ink)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.username)
                    .font(.system(size: 15, weight: entry.isMe ? .bold : .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(entry.rank.displayName)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.totalXP)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("XP")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(14)
        .background(entry.isMe ? Theme.highlight.opacity(0.15) : Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(entry.isMe ? Theme.highlight : .clear, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)

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

    private func rankBadgeColor(rank: Int) -> Color {
        switch rank {
        case 1: return Color(hex: "FFD700")
        case 2: return Color(hex: "C0C0C0")
        case 3: return Color(hex: "CD7F32")
        default: return Theme.surfaceSecondary
        }
    }
}
