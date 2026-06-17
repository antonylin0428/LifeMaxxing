import Foundation

struct FriendsResponse: Decodable {
    let friends: [Friendship]
}

struct PendingRequestsResponse: Decodable {
    let received: [FriendRequest]
    let sent: [SentFriendRequest]
}

struct SentFriendRequest: Decodable, Identifiable {
    var id: String { recipientSub }
    let recipientSub: String
    let createdAt: String
}

struct LeaderboardResponse: Decodable {
    let leaderboard: [LeaderboardEntry]
}

struct FriendRequestBody: Encodable {
    let recipientSub: String
}

struct FriendDecisionBody: Encodable {
    let requesterSub: String
}

struct UserSearchResult: Decodable, Identifiable {
    var id: String { sub }
    let username: String
    let sub: String
    let rank: Rank
}

struct FriendsAPI {
    static let shared = FriendsAPI()

    func search(username: String) async throws -> UserSearchResult {
        try await APIClient.shared.request(path: "/friends/search?username=\(username)")
    }

    func sendRequest(toSub recipientSub: String) async throws {
        let body = FriendRequestBody(recipientSub: recipientSub)
        let _: EmptyResponse = try await APIClient.shared.request(path: "/friends/request", method: .post, body: body)
    }

    func acceptRequest(fromSub requesterSub: String) async throws {
        let body = FriendDecisionBody(requesterSub: requesterSub)
        let _: EmptyResponse = try await APIClient.shared.request(path: "/friends/accept", method: .post, body: body)
    }

    func declineRequest(fromSub requesterSub: String) async throws {
        let body = FriendDecisionBody(requesterSub: requesterSub)
        let _: EmptyResponse = try await APIClient.shared.request(path: "/friends/decline", method: .post, body: body)
    }

    func listFriends() async throws -> [Friendship] {
        let response: FriendsResponse = try await APIClient.shared.request(path: "/friends")
        return response.friends
    }

    func listPendingRequests() async throws -> PendingRequestsResponse {
        try await APIClient.shared.request(path: "/friends/requests")
    }

    func leaderboard() async throws -> [LeaderboardEntry] {
        let response: LeaderboardResponse = try await APIClient.shared.request(path: "/leaderboard/friends")
        return response.leaderboard
    }
}
