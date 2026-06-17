import Foundation

struct FriendRequest: Codable, Identifiable {
    var id: String { requesterSub }
    let requesterSub: String
    let requesterUsername: String
    let createdAt: String
}
