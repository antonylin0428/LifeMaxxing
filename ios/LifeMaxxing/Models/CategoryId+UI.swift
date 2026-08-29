import SwiftUI

extension CategoryId {
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
