import Foundation

struct FeedPost: Codable, Identifiable {
    var id: String { s3Key }
    let username: String
    let rank: String
    let currentStreak: Int
    let s3Key: String
    let photoUrl: String
    let xpAwarded: Int
    let completedAt: String
}
