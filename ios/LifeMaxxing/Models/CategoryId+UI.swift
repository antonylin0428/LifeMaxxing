import SwiftUI

extension CategoryId {
    var questPrompt: String {
        switch self {
        case .fitness:
            return "Complete a workout, go for a run, or do any form of physical activity today. Even a 20-minute walk counts."
        case .screenDiscipline:
            return "Stay off social media and limit recreational screen time. Put the phone down and be present."
        case .focus:
            return "Put in deep, focused work or study time. No distractions — just you and the task at hand."
        case .personalGoals:
            return "Make meaningful progress on one of your personal goals. One step forward is all it takes."
        case .reflection:
            return "Take time to journal, meditate, or reflect on your day. Clarity comes from slowing down."
        case .spiritual:
            return "Engage in prayer, reading, or a spiritual practice that centers and grounds you."
        }
    }

    var color: Color {
        switch self {
        case .fitness:          return Color(hex: "FFE07A")
        case .screenDiscipline: return Color(hex: "A8D4F5")
        case .focus:            return Color(hex: "C5B5F5")
        case .personalGoals:    return Color(hex: "B0E8AC")
        case .reflection:       return Color(hex: "F5B0CC")
        case .spiritual:        return Color(hex: "F5D2A8")
        }
    }
}
