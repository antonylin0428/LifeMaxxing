import Foundation

struct CreateCommunityRequest: Encodable {
    let name: String
    let description: String?
}

struct CommunitiesAPI {
    static let shared = CommunitiesAPI()

    /// Server independently re-checks isPremium and returns 403 if it's
    /// false - this call can fail even past the frontend gate (e.g. a
    /// stale cached profile), and callers should surface that.
    func createCommunity(name: String, description: String?) async throws -> Community {
        let body = CreateCommunityRequest(name: name, description: description)
        return try await APIClient.shared.request(path: "/communities", method: .post, body: body)
    }
}
