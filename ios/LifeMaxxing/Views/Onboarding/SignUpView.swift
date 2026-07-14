import SwiftUI

struct SignUpView: View {
    @Environment(AuthViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        Form {
            TextField("Username", text: $viewModel.username)
                .textInputAutocapitalization(.never)
            TextField("Email", text: $viewModel.email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            SecureField("Password", text: $viewModel.password)

            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
            }

            Button("Create Account") {
                Task { await viewModel.signUp() }
            }
            .disabled(viewModel.isLoading)
        }
        .navigationTitle("Sign Up")
    }
}
