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

    func signIn() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await AuthService.shared.signIn(email: email, password: password)
            appState.isSignedIn = true
            appState.currentUsername = username
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
