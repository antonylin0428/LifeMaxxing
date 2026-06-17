import Foundation

/// Mirrors the POST /tasks/complete response. The XP reward UI must only
/// ever display values from a decoded instance of this struct - never a
/// locally-computed guess.
struct CompleteTaskResult: Codable {
    let finalXPAwarded: Int
    let newTotalXP: Int
    let newStreak: Int
    let newMultiplier: Double
    let newRank: Rank
    let rankChanged: Bool
    let categoryXPRemainingToday: Int
    let totalXPRemainingToday: Int
}
