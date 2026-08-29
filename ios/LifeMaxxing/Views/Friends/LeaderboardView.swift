import SwiftUI

struct LeaderboardView: View {
    @State private var viewModel = LeaderboardViewModel()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                        leaderboardRow(rank: index + 1, entry: entry)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .refreshable { await viewModel.load() }
            .overlay {
                if viewModel.isLoading && viewModel.entries.isEmpty { LoadingView() }
            }
        }
        .navigationTitle("Leaderboard")
        .task { await viewModel.load() }
        .safeAreaInset(edge: .bottom) {
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }
        }
    }

    private func leaderboardRow(rank: Int, entry: LeaderboardEntry) -> some View {
        HStack(spacing: 14) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankBadgeColor(rank: rank))
                    .frame(width: 36, height: 36)
                Text("#\(rank)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(rank <= 3 ? .white : Theme.textSecondary)
            }

            // Avatar
            Circle()
                .fill(Color(hex: "E8E8E4"))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(entry.username.prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Theme.ink)
                )

            // Name + rank
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
        .background(entry.isMe
                    ? Theme.highlight.opacity(0.15)
                    : Theme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(entry.isMe ? Theme.highlight : .clear, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
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
