import SwiftUI

struct ProfileView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var viewModel = ProfileViewModel()

    var body: some View {
        List {
            if let user = viewModel.user {
                Section {
                    Text(user.rank.displayName)
                        .font(.title2.bold())
                    Text("\(user.totalXP) lifetime XP")
                        .foregroundStyle(.secondary)
                }
                Section("Category Streaks") {
                    ForEach(viewModel.categories) { category in
                        HStack {
                            Text(category.categoryId.displayName)
                            Spacer()
                            Text("\(category.currentStreak)d (longest \(category.longestStreak)d)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
            }
            Section {
                Button("Sign Out", role: .destructive) {
                    Task { await authViewModel.signOut() }
                }
            }
        }
        .overlay {
            if viewModel.isLoading { LoadingView() }
        }
        .navigationTitle("Profile")
        .task { await viewModel.load() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("Friends") { FriendsListView() }
            }
        }
    }
}
