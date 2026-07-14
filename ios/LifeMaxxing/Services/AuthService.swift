import Amplify
import AWSCognitoAuthPlugin
import AWSPluginsCore
import Foundation

/// Wraps Amplify Auth so the rest of the app never touches Cognito SDK
/// types directly. Amplify handles the SRP math for sign-in - do not
/// hand-roll it. Tokens live wherever Amplify's Cognito plugin stores them
/// (Keychain), never in UserDefaults.
@MainActor
final class AuthService {
    static let shared = AuthService()
    private var isConfigured = false

    private init() {}

    /// Configures Amplify programmatically (no amplifyconfiguration.json
    /// needed) using the Cognito User Pool / App Client IDs from the SAM
    /// stack outputs. Call once at app launch.
    func configure() throws {
        guard !isConfigured else { return }

        // Built up with an explicit JSONValue annotation - inlining this as
        // one deeply-nested dictionary literal trips up Swift's type
        // checker (ambiguous JSONValue vs Any inference).
        let cognitoPluginConfig: JSONValue = [
            "CognitoUserPool": [
                "Default": [
                    "PoolId": JSONValue.string(Constants.cognitoUserPoolId),
                    "AppClientId": JSONValue.string(Constants.cognitoAppClientId),
                    "Region": JSONValue.string(Constants.cognitoRegion),
                ],
            ],
        ]
        let authConfiguration = AuthCategoryConfiguration(
            plugins: ["awsCognitoAuthPlugin": cognitoPluginConfig]
        )
        let configuration = AmplifyConfiguration(auth: authConfiguration)

        try Amplify.add(plugin: AWSCognitoAuthPlugin())
        try Amplify.configure(configuration)
        isConfigured = true
    }

    func signUp(email: String, password: String, username: String) async throws {
        let attributes = [AuthUserAttribute(.preferredUsername, value: username)]
        let options = AuthSignUpRequest.Options(userAttributes: attributes)
        do {
            _ = try await Amplify.Auth.signUp(username: email, password: password, options: options)
        } catch {
            throw Self.mapCognitoError(error)
        }
    }

    func confirmSignUp(email: String, code: String) async throws {
        do {
            _ = try await Amplify.Auth.confirmSignUp(for: email, confirmationCode: code)
        } catch {
            throw Self.mapCognitoError(error)
        }
    }

    /// Re-sends the sign-up confirmation code - the Amplify equivalent of
    /// Cognito's ResendConfirmationCode. Used both for an explicit "resend"
    /// tap and to recover from usernameExists/userNotConfirmed below.
    func resendConfirmationCode(email: String) async throws {
        do {
            _ = try await Amplify.Auth.resendSignUpCode(for: email)
        } catch {
            throw Self.mapCognitoError(error)
        }
    }

    func signIn(email: String, password: String) async throws {
        do {
            let result = try await Amplify.Auth.signIn(username: email, password: password)
            guard result.isSignedIn else {
                throw AuthServiceError.signInIncomplete
            }
        } catch let ownError as AuthServiceError {
            // Re-throw without remapping so AuthServiceError.signInIncomplete isn't lost.
            throw ownError
        } catch let authError as AuthError {
            if case .invalidState = authError {
                // "error code 5" — Amplify's state machine has a stale Keychain entry
                // from a previous Cognito User Pool (happens after a SAM stack redeploy).
                // Clear it and retry once; on failure, surface the real error.
                _ = await Amplify.Auth.signOut()
                let retryResult: AuthSignInResult
                do {
                    retryResult = try await Amplify.Auth.signIn(username: email, password: password)
                } catch {
                    throw Self.mapCognitoError(error)
                }
                guard retryResult.isSignedIn else {
                    throw AuthServiceError.signInIncomplete
                }
            } else {
                throw Self.mapCognitoError(authError)
            }
        } catch {
            throw Self.mapCognitoError(error)
        }
    }

    /// Translates Amplify's AuthError (which conforms to AmplifyError, NOT
    /// LocalizedError) into AuthServiceError which does conform to LocalizedError.
    /// Without this, error.localizedDescription produces "error code N" where N is
    /// the AuthError enum case index, since Swift bridges the error to NSError.
    private static func mapCognitoError(_ error: Error) -> Error {
        if error is AuthServiceError { return error }

        guard let authError = error as? AuthError else { return error }

        switch authError {
        case .notAuthorized:
            return AuthServiceError.message("Incorrect email or password.")

        case .service(_, _, let underlying):
            if let cognitoError = underlying as? AWSCognitoAuthError {
                switch cognitoError {
                case .usernameExists:
                    return AuthServiceError.usernameAlreadyExists
                case .userNotConfirmed:
                    return AuthServiceError.userNotConfirmed
                case .userNotFound:
                    return AuthServiceError.message("No account found with that email.")
                case .invalidPassword:
                    return AuthServiceError.message(
                        "Password must be at least 8 characters and include an uppercase letter, lowercase letter, number, and symbol."
                    )
                case .codeMismatch:
                    return AuthServiceError.message("Incorrect verification code. Please try again.")
                case .codeExpired:
                    return AuthServiceError.message("Verification code has expired. Tap \"Resend Code\" to get a new one.")
                case .limitExceeded, .failedAttemptsLimitExceeded, .requestLimitExceeded:
                    return AuthServiceError.message("Too many attempts. Please wait a moment and try again.")
                case .invalidParameter:
                    return AuthServiceError.message("Invalid input. Check your email and try again.")
                case .network:
                    return AuthServiceError.message("Network error. Check your connection and try again.")
                default:
                    break
                }
            }
            return AuthServiceError.message(authError.errorDescription)

        case .validation(_, let description, _, _):
            return AuthServiceError.message(description)

        case .invalidState:
            return AuthServiceError.message("Sign-in failed due to a session conflict. Please try again.")

        case .signedOut:
            return AuthServiceError.message("Session ended. Please sign in again.")

        case .sessionExpired:
            return AuthServiceError.message("Your session has expired. Please sign in again.")

        case .configuration(let description, _, _):
            return AuthServiceError.message("App configuration error: \(description)")

        default:
            return AuthServiceError.message(authError.errorDescription)
        }
    }

    func signOut() async {
        _ = await Amplify.Auth.signOut()
    }

    /// The Access token (NOT the ID token) is what every API Gateway call
    /// must send as `Authorization: Bearer <token>`.
    func currentAccessToken() async throws -> String {
        let session = try await Amplify.Auth.fetchAuthSession()
        guard let cognitoSession = session as? AuthCognitoTokensProvider else {
            throw AuthServiceError.noSession
        }
        let tokens = try cognitoSession.getCognitoTokens().get()
        return tokens.accessToken
    }
}

enum AuthServiceError: Error {
    case signInIncomplete
    case noSession
    /// Re-signed-up with an email that already has an unconfirmed account.
    case usernameAlreadyExists
    /// Signed in with an account that never finished email verification.
    case userNotConfirmed
    /// Generic message for errors where Amplify gives us a description string
    /// but no specific typed case — avoids leaking raw "error code N" to the UI.
    case message(String)
}

extension AuthServiceError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .signInIncomplete:
            return "Sign-in did not complete. Please try again."
        case .noSession:
            return "No active session."
        case .usernameAlreadyExists:
            return "You already started signing up with this email — resending your verification code."
        case .userNotConfirmed:
            return "This email hasn't been verified yet — resending your verification code."
        case .message(let text):
            return text
        }
    }
}
