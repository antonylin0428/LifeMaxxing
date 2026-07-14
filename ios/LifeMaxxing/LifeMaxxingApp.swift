import SwiftUI

@main
struct LifeMaxxingApp: App {
    @State private var appState: AppState
    @State private var authViewModel: AuthViewModel

    init() {
        let state = AppState()
        _appState = State(initialValue: state)
        _authViewModel = State(initialValue: AuthViewModel(appState: state))
        try? AuthService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(authViewModel)
        }
    }
}

/// Routes between the signed-out, pending-verification, and signed-in flows
/// based on AppState/AuthViewModel. Pending verification is checked here -
/// not via a per-screen navigationDestination - so there's always exactly
/// one way back to VerifyEmailView no matter how far the user backs out
/// (Welcome, Sign Up, or Sign In all funnel through this same check).
struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        if appState.isSignedIn {
            MainTabView()
        } else if authViewModel.pendingVerificationEmail != nil {
            NavigationStack { VerifyEmailView() }
        } else {
            WelcomeView()
        }
    }
}
