import Foundation
import Observation

/// App-wide signed-in/signed-out state. AuthViewModel is the only thing
/// that should flip `isSignedIn` - it does so after a real Cognito
/// sign-in/sign-out, never optimistically.
@Observable
final class AppState {
    var isSignedIn: Bool = false
    var currentUsername: String?
}
