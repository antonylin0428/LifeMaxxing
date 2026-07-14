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
                Section("Communities") {
                    NavigationLink("Create a Community") {
                        if user.isPremium {
                            CreateCommunityView()
                        } else {
                            PremiumUpsellView()
                        }
                    }
                }
                Section {
                    Toggle("Premium Access (mock)", isOn: Binding(
                        get: { user.isPremium },
                        set: { newValue in Task { await viewModel.setMockPremium(newValue) } }
                    ))
                } header: {
                    Text("Developer / Testing")
                } footer: {
                    Text("No real payment - toggles the mock isPremium flag used to test the Create Community gate.")
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
    }
}
