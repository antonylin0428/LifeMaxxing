import Amplify
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
        Self.applyGlobalAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(authViewModel)
        }
    }

    private static func applyGlobalAppearance() {
        let bgColor = UIColor(red: 0.965, green: 0.961, blue: 0.949, alpha: 1)
        let textColor = UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 1)

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = bgColor
        nav.shadowColor = .clear
        nav.titleTextAttributes = [.foregroundColor: textColor]
        nav.largeTitleTextAttributes = [.foregroundColor: textColor]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().tintColor = textColor
    }
}

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        Group {
            if appState.isSignedIn {
                MainTabView()
            } else if authViewModel.pendingVerificationEmail != nil {
                NavigationStack { VerifyEmailView() }
            } else {
                WelcomeView()
            }
        }
        .task {
            guard !appState.isSignedIn else { return }
            if let session = try? await Amplify.Auth.fetchAuthSession(),
               session.isSignedIn {
                appState.isSignedIn = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sessionExpired)) { _ in
            Task {
                await AuthService.shared.signOut()
                appState.isSignedIn = false
            }
        }
    }
}
