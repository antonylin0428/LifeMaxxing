import SwiftUI

struct VerifyEmailView: View {
    @Environment(AuthViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "B0E8AC").opacity(0.5))
                                .frame(width: 64, height: 64)
                            Image(systemName: "envelope.badge.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(Color(hex: "2A8A28"))
                        }
                        .padding(.bottom, 4)

                        Text("Check your email")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text("Enter the code sent to **\(viewModel.pendingVerificationEmail ?? "your email")**")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.top, 8)

                    ThemedTextField("Verification Code", text: $viewModel.verificationCode, iconName: "number")
                        .keyboardType(.numberPad)

                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error)
                    }

                    Button("Verify Email") {
                        Task { await viewModel.confirmSignUp() }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(viewModel.isLoading)

                    VStack(spacing: 12) {
                        Button("Resend Code") {
                            Task { await viewModel.resendVerificationCode() }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(viewModel.isLoading)

                        Button("Use a Different Email") {
                            viewModel.cancelVerification()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "FF4444"))
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)

            if viewModel.isLoading {
                LoadingView()
            }
        }
        .navigationTitle("Verify Email")
        .navigationBarTitleDisplayMode(.inline)
    }
}
