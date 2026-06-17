import SwiftUI

struct FriendsListView: View {
    @State private var viewModel = FriendsViewModel()

    var body: some View {
        List {
            Section("Friends") {
                ForEach(viewModel.friends) { friend in
                    Text(friend.friendUsername)
                }
            }
            Section("Pending Requests") {
                ForEach(viewModel.received) { request in
                    HStack {
                        Text(request.requesterUsername)
                        Spacer()
                        Button("Accept") { Task { await viewModel.accept(request) } }
                            .buttonStyle(.borderedProminent)
                        Button("Decline") { Task { await viewModel.decline(request) } }
                            .buttonStyle(.bordered)
                    }
                }
            }
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
            }
        }
        .overlay {
            if viewModel.isLoading { LoadingView() }
        }
        .navigationTitle("Friends")
        .task { await viewModel.load() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("Add") { AddFriendView() }
            }
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink("Leaderboard") { LeaderboardView() }
            }
        }
    }
}
