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

/// Routes between the signed-out and signed-in flows based on AppState.
/// Kept tiny on purpose - all real navigation logic lives under each flow.
struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        if appState.isSignedIn {
            MainTabView()
        } else {
            WelcomeView()
        }
    }
}
