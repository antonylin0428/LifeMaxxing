import SwiftUI

/// The tap-to-complete category list. This used to be the entire signed-in
/// app (as HomeView); now it's the "Quests" tab while Home is the dashboard
/// overview.
struct QuestsView: View {
    @State private var viewModel = QuestsViewModel()

    var body: some View {
        ZStack {
            List(viewModel.categories.filter { $0.enabled != false }) { category in
                let done = viewModel.isCompletedToday(category)
                Button {
                    guard !done else { return }
                    Task { await viewModel.complete(category.categoryId) }
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(category.categoryId.displayName)
                                .font(.headline)
                                .foregroundStyle(done ? .secondary : .primary)
                            Text(done ? "Done today ✓" : "Streak: \(category.currentStreak) days")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: done ? "checkmark.circle.fill" : "checkmark.circle")
                            .foregroundStyle(done ? .green : .secondary)
                    }
                }
                .disabled(done)
            }
            .overlay {
                if viewModel.isLoading { LoadingView() }
            }
            .refreshable { await viewModel.load() }

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
