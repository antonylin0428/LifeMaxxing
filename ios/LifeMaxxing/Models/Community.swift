import Foundation

struct Community: Codable, Identifiable, Hashable {
    var id: String { communityId }
    let communityId: String
    let name: String
    let description: String?
    let createdBy: String
    let createdByUsername: String
    let createdAt: String
    let memberCount: Int?
    /// Short shareable code (e.g. "7K3QF9") that joinCommunityByCode resolves.
    let inviteCode: String?
}

struct CommunityInvite: Codable, Identifiable {
    var id: String { communityId }
    let communityId: String
    let communityName: String
    let invitedByUsername: String
    let createdAt: String
}

struct CommunityInvitesResponse: Codable {
    let invites: [CommunityInvite]
}

struct JoinCommunityResponse: Codable {
    let joined: Bool
    let communityId: String
    let name: String
}

/// The community leaderboard ranks by communityXP (a per-community counter,
/// separate from the user's global totalXP) - the response field is still
/// named totalXP to avoid an extra client-side rename, but it's populated
/// server-side from communityXP now (see getCommunityLeaderboard).
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
