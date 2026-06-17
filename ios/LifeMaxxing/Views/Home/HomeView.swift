import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink("Profile") { ProfileView() }
                }
            }
            .task { await viewModel.load() }
            .safeAreaInset(edge: .bottom) {
                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error).padding()
                }
            }
        }
    }
}
