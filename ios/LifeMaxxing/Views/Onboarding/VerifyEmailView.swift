import SwiftUI

struct VerifyEmailView: View {
    @Environment(AuthViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        Form {
            Text("Enter the verification code sent to \(viewModel.pendingVerificationEmail ?? "your email")")
            TextField("Verification Code", text: $viewModel.verificationCode)
                .keyboardType(.numberPad)

            if let error = viewModel.errorMessage {
                ErrorBanner(message: error)
            }

            Button("Verify") {
                Task { await viewModel.confirmSignUp() }
            }
            .disabled(viewModel.isLoading)

            Button("Resend Code") {
                Task { await viewModel.resendVerificationCode() }
            }
            .disabled(viewModel.isLoading)

            Button("Use a Different Email", role: .destructive) {
                viewModel.cancelVerification()
            }
        }
        .navigationTitle("Verify Email")
    }
}
