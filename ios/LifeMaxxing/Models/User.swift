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
    /// Set to true after the $2.99 StoreKit one-time purchase is verified server-side.
    let hasCommunityAccess: Bool
    /// Set of achievement IDs granted server-side (e.g. "first-workout", "streak-7").
    let achievements: [String]?
}
