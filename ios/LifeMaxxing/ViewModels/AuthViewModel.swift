import Foundation
import Observation

@Observable
@MainActor
final class AuthViewModel {
    var email = ""
    var password = ""
    var username = ""
    var verificationCode = ""
    var errorMessage: String?
    var isLoading = false
    var pendingVerificationEmail: String?

    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func signUp() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await AuthService.shared.signUp(email: email, password: password, username: username)
            pendingVerificationEmail = email
        } catch AuthServiceError.usernameAlreadyExists {
            // This email already has an unconfirmed account from a previous
            // attempt - resume verification instead of dead-ending on
            // Cognito's anti-enumeration error.
            await recoverPendingVerification(email: email, message: AuthServiceError.usernameAlreadyExists.errorDescription)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmSignUp() async {
        guard let email = pendingVerificationEmail else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await AuthService.shared.confirmSignUp(email: email, code: verificationCode)
            pendingVerificationEmail = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Lets a user abandon a stuck/unwanted verification (e.g. typo'd email)
    /// and return to Welcome instead of being stuck with no way out.
    func cancelVerification() {
        pendingVerificationEmail = nil
        verificationCode = ""
        errorMessage = nil
    }

    func resendVerificationCode() async {
        guard let email = pendingVerificationEmail else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await AuthService.shared.resendConfirmationCode(email: email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await AuthService.shared.signIn(email: email, password: password)
            appState.isSignedIn = true
            appState.currentUsername = username
        } catch AuthServiceError.userNotConfirmed {
            // Account exists but never finished email verification - route
            // back into Verify rather than leaving them stuck on Sign In.
            await recoverPendingVerification(email: email, message: AuthServiceError.userNotConfirmed.errorDescription)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func recoverPendingVerification(email: String, message: String?) async {
        do {
            try await AuthService.shared.resendConfirmationCode(email: email)
            pendingVerificationEmail = email
            errorMessage = message
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        await AuthService.shared.signOut()
        appState.isSignedIn = false
        appState.currentUsername = nil
    }
}
