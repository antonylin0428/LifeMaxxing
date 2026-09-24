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

    func getCommunityFeed(id: String) async throws -> [CommunityFeedPost] {
        return try await APIClient.shared.request(path: "/communities/\(id)/feed", method: .get)
    }

    func getCommunityFeedUploadUrl(id: String) async throws -> CommunityFeedUploadUrlResponse {
        return try await APIClient.shared.request(path: "/communities/\(id)/feed/upload-url", method: .get)
    }

    func postCommunityPhoto(communityId: String, s3Key: String) async throws {
        struct PostBody: Encodable { let photoS3Key: String }
        struct PostResponse: Decodable { let posted: Bool }
        let _: PostResponse = try await APIClient.shared.request(
            path: "/communities/\(communityId)/feed", method: .post,
            body: PostBody(photoS3Key: s3Key))
    }

    // MARK: - Community Goals

    func getCommunityGoals(id: String) async throws -> [CommunityGoal] {
        let response: CommunityGoalsResponse = try await APIClient.shared.request(
            path: "/communities/\(id)/goals", method: .get)
        return response.goals
    }

    func updateCommunityGoals(id: String, goals: [CommunityGoalDraft]) async throws -> [CommunityGoal] {
        let body = UpdateCommunityGoalsRequest(goals: goals.enumerated().map { idx, g in
            UpdateCommunityGoalsRequest.Goal(
                goalId: g.id, name: g.name,
                description: g.description.isEmpty ? nil : g.description,
                emoji: g.emoji, trackingType: g.trackingType.rawValue, order: idx)
        })
        struct Response: Decodable { let goals: [CommunityGoal] }
        let response: Response = try await APIClient.shared.request(
            path: "/communities/\(id)/goals", method: .put, body: body)
        return response.goals
    }

    func getCommunityGoalUploadUrl(communityId: String, goalId: String) async throws -> CommunityGoalUploadUrlResponse {
        try await APIClient.shared.request(
            path: "/communities/\(communityId)/goals/\(goalId)/upload-url", method: .get)
    }

    func completeCommunityGoal(communityId: String, goalId: String, photoS3Key: String?, text: String?) async throws {
        struct Body: Encodable { let photoS3Key: String?; let text: String? }
        struct Response: Decodable { let completed: Bool }
        let _: Response = try await APIClient.shared.request(
            path: "/communities/\(communityId)/goals/\(goalId)/complete",
            method: .post, body: Body(photoS3Key: photoS3Key, text: text))
    }

    func getCommunityGoalFeed(communityId: String, goalId: String) async throws -> [CommunityGoalCompletion] {
        try await APIClient.shared.request(
            path: "/communities/\(communityId)/goals/\(goalId)/feed", method: .get)
    }

    func uploadCommunityPhoto(_ data: Data, to uploadUrl: String) async throws {
        guard let url = URL(string: uploadUrl) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await URLSession.shared.upload(for: request, from: data)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
