import Foundation

struct Community: Codable, Identifiable {
    var id: String { communityId }
    let communityId: String
    let name: String
    let description: String?
    let createdBy: String
    let createdByUsername: String
    let createdAt: String
    let memberCount: Int?
}

struct CommunityLeaderboardEntry: Codable, Identifiable {
    var id: String { sub }
    let sub: String
    let username: String
    let totalXP: Int
    let rank: Rank?
    let isMe: Bool
}

struct CommunityLeaderboardResponse: Codable {
    let communityId: String
    let name: String
    let leaderboard: [CommunityLeaderboardEntry]
}

struct CommunitiesListResponse: Codable {
    let communities: [Community]
}
