import Foundation

struct Friendship: Codable, Identifiable {
    var id: String { friendSub }
    let friendSub: String
    let friendUsername: String
    let becameFriendsAt: String
}

struct LeaderboardEntry: Codable, Identifiable {
    var id: String { sub }
    let sub: String
    let username: String
    let totalXP: Int
    let rank: Rank
    let isMe: Bool
}
