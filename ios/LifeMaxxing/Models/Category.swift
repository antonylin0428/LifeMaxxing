import Foundation

/// Mirrors backend/layers/shared/.../xpRules.js CATEGORIES. Keep in sync -
/// the categoryId string sent to POST /tasks/complete must match exactly.
enum CategoryId: String, Codable, CaseIterable, Identifiable {
    var id: String { rawValue }

    case fitness = "FITNESS"
    case screenDiscipline = "SCREEN_DISCIPLINE"
    case focus = "FOCUS"
    case personalGoals = "PERSONAL_GOALS"
    case reflection = "REFLECTION"
    case spiritual = "SPIRITUAL"

    var displayName: String {
        switch self {
        case .fitness: return "Fitness"
        case .screenDiscipline: return "Screen Discipline"
        case .focus: return "Study / Work"
        case .personalGoals: return "Personal Goals"
        case .reflection: return "Reflection"
        case .spiritual: return "Spiritual Journey"
        }
    }

    var isOptional: Bool {
        self == .reflection || self == .spiritual
    }

    var systemImageName: String {
        switch self {
        case .fitness: return "figure.strengthtraining.traditional"
        case .screenDiscipline: return "iphone"
        case .focus: return "book.fill"
        case .personalGoals: return "target"
        case .reflection: return "leaf.fill"
        case .spiritual: return "sparkles"
        }
    }
}

/// Mirrors a CategoryStats item returned by GET /me/categories.
struct CategoryStat: Codable, Identifiable {
    var id: String { categoryId.rawValue }
    let categoryId: CategoryId
    let currentStreak: Int
    let longestStreak: Int
    let lastCompletedDate: String?
    let multiplierCache: Double?
    let freezesAvailable: Int
    let enabled: Bool?
}
