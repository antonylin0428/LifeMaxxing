import Foundation

private struct CreateCommunityRequest: Encodable {
    let name: String
    let description: String?
}

struct CommunitiesAPI {
    static let shared = CommunitiesAPI()

    func createCommunity(name: String, description: String?) async throws -> Community {
        let body = CreateCommunityRequest(name: name, description: description)
        return try await APIClient.shared.request(path: "/communities", method: .post, body: body)
    }

    func getCommunity(id: String) async throws -> Community {
        return try await APIClient.shared.request(path: "/communities/\(id)", method: .get)
    }

    func joinCommunity(id: String) async throws {
        struct JoinResponse: Decodable { let joined: Bool }
        let _: JoinResponse = try await APIClient.shared.request(
            path: "/communities/\(id)/join", method: .post)
    }

    func listMyCommunities() async throws -> [Community] {
        let response: CommunitiesListResponse = try await APIClient.shared.request(
            path: "/me/communities", method: .get)
        return response.communities
    }

    func getCommunityLeaderboard(id: String) async throws -> CommunityLeaderboardResponse {
        return try await APIClient.shared.request(
            path: "/communities/\(id)/leaderboard", method: .get)
    }
}
