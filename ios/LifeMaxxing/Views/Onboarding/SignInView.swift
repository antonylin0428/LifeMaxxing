import SwiftUI

struct SignInView: View {
    @Environment(AuthViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        Form {
            TextField("Email", text: $viewModel.email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
            SecureField("Password", text: $viewModel.password)

            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
            }

            Button("Sign In") {
                Task { await viewModel.signIn() }
            }
            .disabled(viewModel.isLoading)
        }
        .navigationTitle("Sign In")
    }
}
