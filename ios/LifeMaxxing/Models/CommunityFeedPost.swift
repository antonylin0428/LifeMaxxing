import Foundation

struct CommunityFeedPost: Codable, Identifiable {
    var id: String { userSub }
    let userSub: String
    let username: String
    let rank: String
    let photoUrl: String
    let postedAt: String
    let isMe: Bool
}

struct CommunityFeedUploadUrlResponse: Decodable {
    let uploadUrl: String
    let s3Key: String
}
