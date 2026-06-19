import SwiftUI

/// Dark/purple/gold palette matching the brand mockup (brand/Screenshot ...).
/// Centralized here so screens don't hardcode hex values individually.
enum Theme {
    static let background = Color(red: 0.07, green: 0.05, blue: 0.12)
    static let surface = Color(red: 0.12, green: 0.10, blue: 0.18)
    static let surfaceElevated = Color(red: 0.16, green: 0.13, blue: 0.24)
    static let accentGold = Color(red: 0.96, green: 0.74, blue: 0.27)
    static let accentPurple = Color(red: 0.55, green: 0.40, blue: 0.95)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardBackground())
    }
}
