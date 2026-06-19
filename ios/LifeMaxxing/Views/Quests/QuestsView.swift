import SwiftUI

/// The tap-to-complete category list. This used to be the entire signed-in
/// app (as HomeView); now it's the "Quests" tab while Home is the dashboard
/// overview.
struct QuestsView: View {
    @State private var viewModel = QuestsViewModel()

    var body: some View {
        ZStack {
            List(viewModel.categories) { category in
                Button {
                    Task { await viewModel.complete(category.categoryId) }
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(category.categoryId.displayName)
                                .font(.headline)
                            Text("Streak: \(category.currentStreak) days")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle")
                    }
                }
            }
            .overlay {
                if viewModel.isLoading { LoadingView() }
            }

            if let reward = viewModel.lastReward {
                XPRewardOverlay(result: reward)
                    .onTapGesture { viewModel.lastReward = nil }
            }
        }
        .navigationTitle("Today")
        .task { await viewModel.load() }
        .safeAreaInset(edge: .bottom) {
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error).padding()
            }
        }
    }
}
