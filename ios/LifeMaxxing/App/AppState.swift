import Foundation
import Observation

/// App-wide signed-in/signed-out state. AuthViewModel is the only thing
/// that should flip `isSignedIn` - it does so after a real Cognito
/// sign-in/sign-out, never optimistically.
@Observable
final class AppState {
    var isSignedIn: Bool = false
    var currentUsername: String?

    // Persisted so returning users skip the onboarding on re-launch
    var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "onboardingComplete") {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "onboardingComplete") }
    }

    // Categories to display on the home screen. Stored so @Observable can
    // propagate changes to HomeView immediately (a computed property would not).
    var localCategoryIds: [CategoryId] = {
        let required = CategoryId.allCases.filter { !$0.isOptional }
        if let raw = UserDefaults.standard.stringArray(forKey: "selectedCategoryIds") {
            let optional = raw.compactMap { CategoryId(rawValue: $0) }.filter { $0.isOptional }
            return required + optional
        }
        return required
    }()

}
