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

    // MARK: - Invites

    func joinCommunity(byCode code: String) async throws -> JoinCommunityResponse {
        struct Body: Encodable { let inviteCode: String }
        return try await APIClient.shared.request(
            path: "/communities/join-by-code", method: .post, body: Body(inviteCode: code))
    }

    func inviteFriend(_ friendSub: String, toCommunity communityId: String) async throws {
        struct Body: Encodable { let friendSub: String }
        struct Response: Decodable { let status: String }
        let _: Response = try await APIClient.shared.request(
            path: "/communities/\(communityId)/invite", method: .post, body: Body(friendSub: friendSub))
    }

    func listCommunityInvites() async throws -> [CommunityInvite] {
        let response: CommunityInvitesResponse = try await APIClient.shared.request(
            path: "/me/community-invites", method: .get)
        return response.invites
    }

    func acceptCommunityInvite(_ communityId: String) async throws -> JoinCommunityResponse {
        struct Response: Decodable { let communityId: String; let name: String; let status: String }
        let r: Response = try await APIClient.shared.request(
            path: "/communities/\(communityId)/invite/accept", method: .post)
        return JoinCommunityResponse(joined: true, communityId: r.communityId, name: r.name)
    }

    func declineCommunityInvite(_ communityId: String) async throws {
        struct Response: Decodable { let status: String }
        let _: Response = try await APIClient.shared.request(
            path: "/communities/\(communityId)/invite/decline", method: .post)
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
                icon: g.icon, trackingType: g.trackingType.rawValue, order: idx,
                targetValue: g.trackingType == .numeric ? Double(g.targetValue) : nil,
                unit: g.trackingType == .numeric ? g.unit : nil,
                direction: g.trackingType == .numeric ? g.direction.rawValue : nil)
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

    @discardableResult
    func completeCommunityGoal(
        communityId: String, goalId: String,
        photoS3Key: String? = nil, text: String? = nil, numericValue: Double? = nil
    ) async throws -> CompleteCommunityGoalResponse {
        struct Body: Encodable { let photoS3Key: String?; let text: String?; let numericValue: Double? }
        return try await APIClient.shared.request(
            path: "/communities/\(communityId)/goals/\(goalId)/complete",
            method: .post, body: Body(photoS3Key: photoS3Key, text: text, numericValue: numericValue))
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
