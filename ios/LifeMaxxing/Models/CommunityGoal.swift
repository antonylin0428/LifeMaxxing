import Foundation

struct CommunityGoal: Codable, Identifiable {
    var id: String { goalId }
    let goalId: String
    let name: String
    let description: String?
    let emoji: String
    let trackingType: TrackingType
    let order: Int
    /// Numeric goals only.
    let targetValue: Double?
    let unit: String?
    let direction: Direction?
    let myCompletion: MyCompletion?

    enum TrackingType: String, Codable, CaseIterable {
        case photo
        case text
        case both
        case numeric

        var displayName: String {
            switch self {
            case .photo: return "Photo"
            case .text: return "Short Message"
            case .both: return "Photo + Message"
            case .numeric: return "Number"
            }
        }

        var needsPhoto: Bool { self == .photo || self == .both }
        var needsText: Bool { self == .text || self == .both }
        var needsNumber: Bool { self == .numeric }
    }

    enum Direction: String, Codable, CaseIterable {
        case atLeast = "at_least"
        case atMost = "at_most"

        var displayName: String {
            switch self {
            case .atLeast: return "At least"
            case .atMost: return "At most"
            }
        }
    }

    struct MyCompletion: Codable {
        let text: String?
        let hasPhoto: Bool
        let numericValue: Double?
        let metTarget: Bool?
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
    let numericValue: Double?
    let metTarget: Bool?
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

struct CompleteCommunityGoalResponse: Codable {
    let completed: Bool
    let metTarget: Bool?
    let xpAwarded: Int
}

// Draft used in the settings editor — not sent to the server directly
struct CommunityGoalDraft: Identifiable, Equatable {
    var id: String
    var name: String
    var description: String
    var emoji: String
    var trackingType: CommunityGoal.TrackingType
    var order: Int
    var targetValue: String
    var unit: String
    var direction: CommunityGoal.Direction

    init(from goal: CommunityGoal) {
        id = goal.goalId
        name = goal.name
        description = goal.description ?? ""
        emoji = goal.emoji
        trackingType = goal.trackingType
        order = goal.order
        targetValue = goal.targetValue.map { String(format: $0.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%g", $0) } ?? ""
        unit = goal.unit ?? ""
        direction = goal.direction ?? .atLeast
    }

    init() {
        id = UUID().uuidString
        name = ""
        description = ""
        emoji = "⭐"
        trackingType = .photo
        order = 0
        targetValue = ""
        unit = ""
        direction = .atLeast
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
        let targetValue: Double?
        let unit: String?
        let direction: String?
    }
    let goals: [Goal]
}
