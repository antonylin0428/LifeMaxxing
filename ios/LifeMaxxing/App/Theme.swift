import SwiftUI

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b)
    }
}

enum Theme {
    static let background       = Color(hex: "FAF0E8")
    static let surface          = Color.white
    static let surfaceSecondary = Color(hex: "F0E4D4")
    static let textPrimary      = Color(hex: "1A1A1A")
    static let textSecondary    = Color(hex: "8A8A8A")
    static let border           = Color(hex: "E8DDD0")
    static let accent           = Color(hex: "E8916A")
    static let accentGreen      = Color(hex: "E8916A")
    static let highlight        = Color(hex: "E8916A")
    static let ink              = Color(hex: "1A1A1A")

    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .ultraLight: name = "AvenirNext-UltraLight"
        case .thin:       name = "AvenirNext-UltraLight"
        case .light:      name = "AvenirNext-Regular"
        case .medium:     name = "AvenirNext-Medium"
        case .semibold:   name = "AvenirNext-DemiBold"
        case .bold:       name = "AvenirNext-Bold"
        case .heavy:      name = "AvenirNext-Heavy"
        case .black:      name = "AvenirNext-Heavy"
        default:          name = "AvenirNext-Regular"
        }
        return .custom(name, size: size)
    }
}

struct CardStyle: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        modifier(CardStyle(padding: padding))
    }
    func lmBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }
}
