import SwiftUI

struct SignInView: View {
    @Environment(AuthViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Sign in to continue your journey")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 12) {
                        ThemedTextField("Email", text: $viewModel.email, iconName: "envelope")
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        ThemedTextField("Password", text: $viewModel.password, isSecure: true, iconName: "lock")
                    }

                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error)
                    }

                    Button("Sign In") {
                        Task { await viewModel.signIn() }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading)
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)

            if viewModel.isLoading {
                LoadingView()
            }
        }
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
    }
}
