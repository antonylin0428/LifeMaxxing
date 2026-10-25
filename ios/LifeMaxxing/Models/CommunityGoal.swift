import Foundation

/// Navigation value for pushing a goal screen - bundles the goal with the
/// community it belongs to. Used instead of pushing CommunityGoal alone so
/// the destination can be registered at a stable root (QuestsView,
/// MyCommunityListView) rather than on CommunityDetailView itself: a
/// navigationDestination(for:) declared on a view that's itself a pushed,
/// frequently-re-rendering destination gets re-registered on every one of
/// that view's re-renders, which makes SwiftUI re-resolve the already-
/// displayed child in a feedback loop that pegs the CPU.
struct CommunityGoalNavigationTarget: Hashable {
    let communityId: String
    let goal: CommunityGoal
}

struct CommunityGoal: Codable, Identifiable, Hashable {
    var id: String { goalId }
    let goalId: String
    let name: String
    let description: String?
    /// SF Symbol name (e.g. "drop.fill"), not a unicode emoji.
    let icon: String
    let trackingType: TrackingType
    let order: Int
    /// Numeric goals only.
    let targetValue: Double?
    let unit: String?
    let direction: Direction?
    let myCompletion: MyCompletion?

    enum TrackingType: String, Codable, CaseIterable, Hashable {
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

    enum Direction: String, Codable, CaseIterable, Hashable {
        case atLeast = "at_least"
        case atMost = "at_most"

        var displayName: String {
            switch self {
            case .atLeast: return "At least"
            case .atMost: return "At most"
            }
        }
    }

    struct MyCompletion: Codable, Hashable {
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
    var icon: String
    var trackingType: CommunityGoal.TrackingType
    var order: Int
    var targetValue: String
    var unit: String
    var direction: CommunityGoal.Direction

    init(from goal: CommunityGoal) {
        id = goal.goalId
        name = goal.name
        description = goal.description ?? ""
        icon = goal.icon
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
        icon = "star.fill"
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
        let icon: String
        let trackingType: String
        let order: Int
        let targetValue: Double?
        let unit: String?
        let direction: String?
    }
    let goals: [Goal]
}
