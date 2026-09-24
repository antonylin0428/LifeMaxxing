import Foundation

struct CommunityGoal: Codable, Identifiable {
    var id: String { goalId }
    let goalId: String
    let name: String
    let description: String?
    let emoji: String
    let trackingType: TrackingType
    let order: Int
    let myCompletion: MyCompletion?

    enum TrackingType: String, Codable, CaseIterable {
        case photo
        case text
        case both

        var displayName: String {
            switch self {
            case .photo: return "Photo"
            case .text: return "Short Message"
            case .both: return "Photo + Message"
            }
        }

        var needsPhoto: Bool { self == .photo || self == .both }
        var needsText: Bool { self == .text || self == .both }
    }

    struct MyCompletion: Codable {
        let text: String?
        let hasPhoto: Bool
        let completedAt: String
    }
}

struct CommunityGoalCompletion: Codable, Identifiable {
    var id: String { userSub }
    let userSub: String
    let username: String
    let rank: String
    let avatarUrl: String?
    let text: String?
    let photoUrl: String?
    let completedAt: String
    let isMe: Bool
}

struct CommunityGoalsResponse: Codable {
    let goals: [CommunityGoal]
}

struct CommunityGoalUploadUrlResponse: Codable {
    let uploadUrl: String
    let s3Key: String
}

// Draft used in the settings editor — not sent to the server directly
struct CommunityGoalDraft: Identifiable, Equatable {
    var id: String
    var name: String
    var description: String
    var emoji: String
    var trackingType: CommunityGoal.TrackingType
    var order: Int

    init(from goal: CommunityGoal) {
        id = goal.goalId
        name = goal.name
        description = goal.description ?? ""
        emoji = goal.emoji
        trackingType = goal.trackingType
        order = goal.order
    }

    init() {
        id = UUID().uuidString
        name = ""
        description = ""
        emoji = "⭐"
        trackingType = .photo
        order = 0
    }
}

struct UpdateCommunityGoalsRequest: Encodable {
    struct Goal: Encodable {
        let goalId: String
        let name: String
        let description: String?
        let emoji: String
        let trackingType: String
        let order: Int
    }
    let goals: [Goal]
}
