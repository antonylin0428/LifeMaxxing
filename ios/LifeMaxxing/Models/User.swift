import Foundation

/// Mirrors the GET /me response. Every field here is server-computed -
/// there is no client-side path that writes totalXP or rank back.
struct User: Codable, Identifiable {
    var id: String { username }
    let username: String
    let email: String
    let totalXP: Int
    let rank: Rank
    let rankIndex: Int
    let activeDaysLast30: Int
    /// Set to true once the user has ever bought a community-creation credit.
    /// Does NOT mean they have one available right now - see communityCreateCredits.
    let hasCommunityAccess: Bool
    /// Remaining community-creation credits (consumable StoreKit purchase,
    /// one community per credit). 0 means they can still JOIN communities
    /// freely, just not create a new one until they buy another credit.
    let communityCreateCredits: Int
    /// Set of achievement IDs granted server-side (e.g. "first-workout", "streak-7").
    let achievements: [String]?
    /// Presigned S3 URL for the user's avatar, present only when they've uploaded one.
    let avatarUrl: String?
}
