import SwiftUI

struct AddFriendView: View {
    @State private var viewModel = FriendsViewModel()
    @State private var didSendRequest = false

    var body: some View {
        @Bindable var viewModel = viewModel
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 16) {
                    ThemedTextField("Search by username", text: $viewModel.searchUsername,
                                    iconName: "magnifyingglass")
                        .textInputAutocapitalization(.never)

                    Button("Search") {
                        didSendRequest = false
                        Task { await viewModel.search() }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.searchUsername.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(20)

                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }

                if let result = viewModel.searchResult {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Result")
                            .padding(.horizontal, 20)

                        HStack(spacing: 14) {
                            Circle()
                                .fill(Color(hex: "A8D4F5").opacity(0.6))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(String(result.username.prefix(1)).uppercased())
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(Theme.ink)
                                )

                            VStack(alignment: .leading, spacing: 3) {
                                Text(result.username)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("LifeMaxxing user")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.textSecondary)
                            }

                            Spacer()

                            Button(didSendRequest ? "Sent ✓" : "Add Friend") {
                                Task {
                                    await viewModel.sendRequest(toSub: result.sub)
                                    didSendRequest = true
                                }
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(didSendRequest ? Theme.textSecondary : .white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(didSendRequest ? Theme.surfaceSecondary : Theme.ink)
                            )
                            .disabled(didSendRequest)
                        }
                        .padding(16)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 20)
                    }
                }

                Spacer()
            }
            .scrollDismissesKeyboard(.interactively)

            if viewModel.isLoading {
                LoadingView()
            }
        }
        .navigationTitle("Add Friend")
        .navigationBarTitleDisplayMode(.inline)
    }
}
