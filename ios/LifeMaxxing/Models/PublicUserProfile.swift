import Foundation

struct PublicUserProfile: Decodable {
    let sub: String
    let username: String
    let rank: Rank
    let totalXP: Int
    let achievements: [String]
    let avatarUrl: String?
    let recentGymPhotoUrl: String?
    let recentGymPhotoDate: String?
}
