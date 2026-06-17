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
}
