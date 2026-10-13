import SwiftUI

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Capsule()
            .fill(configuration.isPressed ? Theme.accent.opacity(0.85) : Theme.ink)
            .frame(height: 52)
            .overlay(
                configuration.label
                    .font(Theme.font(16, .regular))
                    .foregroundStyle(.white)
            )
            .frame(maxWidth: .infinity)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Capsule().fill(Theme.surface)
            Capsule().strokeBorder(Theme.border, lineWidth: 1.5)
            configuration.label
                .font(Theme.font(17, .regular))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(height: 54)
        .frame(maxWidth: .infinity)
        .scaleEffect(configuration.isPressed ? 0.97 : 1)
        .animation(.spring(response: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Text Field
// Callers apply .keyboardType() / .textInputAutocapitalization() as modifiers;
// they propagate through the SwiftUI environment to the inner text field.

struct ThemedTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var iconName: String? = nil

    init(_ placeholder: String, text: Binding<String>, isSecure: Bool = false, iconName: String? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.iconName = iconName
    }

    var body: some View {
        HStack(spacing: 12) {
            if let icon = iconName {
                Image(systemName: icon)
                    .font(Theme.font(17, .regular))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 20)
            }
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(Theme.textSecondary)
                }
                Group {
                    if isSecure {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Stat Tile

struct StatTile: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(Theme.font(19))
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(Theme.font(11, .regular))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Theme.surfaceSecondary)
                    .frame(width: 26, height: 26)
                Image(systemName: icon)
                    .font(Theme.font(12, .regular))
                    .foregroundStyle(Theme.textPrimary)
            }
            Text(label)
                .font(Theme.font(14, .regular))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(Theme.font(11, .regular))
                .foregroundStyle(Theme.textSecondary.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(Theme.font(16))
            .foregroundStyle(Theme.textPrimary)
    }
}
