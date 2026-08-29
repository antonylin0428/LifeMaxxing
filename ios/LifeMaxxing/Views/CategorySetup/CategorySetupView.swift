import SwiftUI

struct CategorySetupView: View {
    @State private var enabledOptional: Set<CategoryId> = []
    @State private var errorMessage: String?

    private let required = CategoryId.allCases.filter { !$0.isOptional }
    private let optional = CategoryId.allCases.filter(\.isOptional)

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Required categories
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Always On")

                        VStack(spacing: 8) {
                            ForEach(required) { category in
                                categoryRow(category: category, isEnabled: true, isToggleable: false)
                            }
                        }
                    }

                    // Optional categories
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Optional")

                        VStack(spacing: 8) {
                            ForEach(optional) { category in
                                categoryRow(
                                    category: category,
                                    isEnabled: enabledOptional.contains(category),
                                    isToggleable: true
                                )
                            }
                        }
                    }

                    if let errorMessage {
                        ErrorBanner(message: errorMessage)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Categories")
    }

    private func categoryRow(category: CategoryId, isEnabled: Bool, isToggleable: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isEnabled ? category.color.opacity(0.7) : Theme.surfaceSecondary)
                    .frame(width: 40, height: 40)
                Image(systemName: category.systemImageName)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(isEnabled ? Theme.ink : Theme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(category.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(isToggleable ? "Optional" : "Required")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            if isToggleable {
                Toggle("", isOn: binding(for: category))
                    .labelsHidden()
                    .tint(Theme.accentGreen)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.accentGreen)
                    .font(.system(size: 20))
            }
        }
        .padding(14)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    private func binding(for category: CategoryId) -> Binding<Bool> {
        Binding(
            get: { enabledOptional.contains(category) },
            set: { isOn in
                if isOn { enabledOptional.insert(category) } else { enabledOptional.remove(category) }
                Task {
                    do {
                        try await ProfileAPI.shared.setCategoryEnabled(category, enabled: isOn)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        )
    }
}
