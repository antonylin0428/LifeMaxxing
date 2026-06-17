import SwiftUI

struct CategorySetupView: View {
    @State private var enabledOptional: Set<CategoryId> = []
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("Always On") {
                ForEach(CategoryId.allCases.filter { !$0.isOptional }) { category in
                    Text(category.displayName)
                }
            }
            Section("Optional") {
                ForEach(CategoryId.allCases.filter(\.isOptional)) { category in
                    Toggle(category.displayName, isOn: binding(for: category))
                }
            }
            if let errorMessage {
                ErrorBanner(message: errorMessage)
            }
        }
        .navigationTitle("Categories")
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
