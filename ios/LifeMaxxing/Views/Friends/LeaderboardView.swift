import SwiftUI

struct LeaderboardView: View {
    @State private var viewModel = LeaderboardViewModel()

    var body: some View {
        List(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
            HStack {
                Text("#\(index + 1)")
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading) {
                    Text(entry.username).fontWeight(entry.isMe ? .bold : .regular)
                    Text(entry.rank.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(entry.totalXP) XP")
            }
        }
        .overlay {
            if viewModel.isLoading { LoadingView() }
        }
        .navigationTitle("Leaderboard")
        .task { await viewModel.load() }
        .safeAreaInset(edge: .bottom) {
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error).padding()
            }
        }
    }
}
