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
        _ = try await Amplify.Auth.signUp(username: email, password: password, options: options)
    }

    func confirmSignUp(email: String, code: String) async throws {
        _ = try await Amplify.Auth.confirmSignUp(for: email, confirmationCode: code)
    }

    func signIn(email: String, password: String) async throws {
        let result = try await Amplify.Auth.signIn(username: email, password: password)
        guard result.isSignedIn else {
            throw AuthServiceError.signInIncomplete
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
}
