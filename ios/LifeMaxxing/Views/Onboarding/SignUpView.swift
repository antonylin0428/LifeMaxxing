import SwiftUI

struct SignUpView: View {
    @Environment(AuthViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create account")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Start your leveling journey today")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 12) {
                        ThemedTextField("Username", text: $viewModel.username, iconName: "person")
                            .textInputAutocapitalization(.never)
                        ThemedTextField("Email", text: $viewModel.email, iconName: "envelope")
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        ThemedTextField("Password", text: $viewModel.password, isSecure: true, iconName: "lock")
                    }

                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error)
                    }

                    Button("Create Account") {
                        Task { await viewModel.signUp() }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading)

                    Text("By creating an account you agree to our Terms of Service.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)

            if viewModel.isLoading {
                LoadingView()
            }
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
    }
}
