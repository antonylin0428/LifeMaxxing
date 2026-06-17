import Foundation

enum Constants {
    // Replace with the HttpApiUrl output from `sam deploy` once the backend is live.
    static let apiBaseURL = URL(string: "https://REPLACE_ME.execute-api.us-east-1.amazonaws.com")!

    // Replace with CognitoUserPoolId / CognitoUserPoolClientId stack outputs.
    static let cognitoUserPoolId = "REPLACE_ME"
    static let cognitoAppClientId = "REPLACE_ME"
    static let cognitoRegion = "us-east-1"
}
