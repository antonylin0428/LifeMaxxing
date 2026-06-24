import Foundation

enum Constants {
    // HttpApiUrl output from the `lifemaxxing-backend` stack (sam deploy, us-east-1).
    static let apiBaseURL = URL(string: "https://z27vkxaq18.execute-api.us-east-1.amazonaws.com")!

    // CognitoUserPoolId / CognitoUserPoolClientId outputs from the same stack.
    static let cognitoUserPoolId = "us-east-1_3IeU7GLZe"
    static let cognitoAppClientId = "13lf28ghgb0pv7310d9a87rf3f"
    static let cognitoRegion = "us-east-1"
}
