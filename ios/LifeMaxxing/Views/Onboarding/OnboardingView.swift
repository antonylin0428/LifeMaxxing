import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var step: Int = 0
    @State private var selectedOptional: Set<CategoryId> = []
    @State private var isSaving = false

    private let required = CategoryId.allCases.filter { !$0.isOptional }
    private let optional = CategoryId.allCases.filter(\.isOptional)

    private var allSelected: [CategoryId] {
        required + optional.filter { selectedOptional.contains($0) }
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if step == 0 {
                welcomeStep
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else if step == 1 {
                categoryStep
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                completionStep
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: step)
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()

            // Decorative category grid
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    welcomeChip(.fitness)
                    welcomeChip(.screenDiscipline)
                    welcomeChip(.focus)
                }
                HStack(spacing: 12) {
                    welcomeChip(.personalGoals)
                    welcomeChip(.reflection)
                    welcomeChip(.spiritual)
                }
            }
            .padding(.bottom, 44)

            VStack(spacing: 10) {
                Text("Welcome to")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                Text("LifeMaxxing")
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
            }

            Spacer().frame(height: 18)

            Text("Build daily habits. Earn XP.\nLevel up your life.")
                .font(.system(size: 16))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Spacer()

            Button("Get Started") {
                withAnimation { step = 1 }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 32)

            Button("Already have an account? Skip") {
                appState.hasCompletedOnboarding = true
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Theme.textSecondary)
            .padding(.top, 16)
            .padding(.bottom, 56)
        }
        .padding(.horizontal, 24)
    }

    private func welcomeChip(_ cat: CategoryId) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cat.color)
                .frame(width: 82, height: 82)
                .shadow(color: cat.color.opacity(0.45), radius: 10, x: 0, y: 5)
            Image(systemName: cat.systemImageName)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Theme.ink.opacity(0.7))
        }
    }

    // MARK: - Step 1: Category Selection

    private var categoryStep: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Pick your goals")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("Required categories are always on.\nTap any optional one to add it.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 72)
            .padding(.bottom, 24)

            ScrollView(showsIndicators: false) {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(CategoryId.allCases) { cat in
                        categoryCard(cat)
                            .onTapGesture {
                                guard cat.isOptional else { return }
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                    if selectedOptional.contains(cat) {
                                        selectedOptional.remove(cat)
                                    } else {
                                        selectedOptional.insert(cat)
                                    }
                                }
                            }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }

            VStack(spacing: 10) {
                Text("\(allSelected.count) of \(CategoryId.allCases.count) categories selected")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)

                Button("Continue") {
                    withAnimation { step = 2 }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 48)
        }
    }

    private func categoryCard(_ cat: CategoryId) -> some View {
        let isRequired = !cat.isOptional
        let isSelected = isRequired || selectedOptional.contains(cat)

        return ZStack(alignment: .topTrailing) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? cat.color : cat.color.opacity(0.22))

                Image(systemName: cat.systemImageName)
                    .font(.system(size: 58, weight: .black))
                    .foregroundStyle(.black.opacity(0.07))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(8)
                    .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 4) {
                    Text(cat.displayName)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(2)
                    Text(isRequired ? "Required" : "Optional")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.ink.opacity(0.45))
                }
                .padding(14)
            }
            .frame(height: 140)

            // Selection badge
            Group {
                if isRequired {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accentGreen)
                        .background(Circle().fill(.white).padding(4))
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.ink)
                        .background(Circle().fill(.white).padding(4))
                } else {
                    Circle()
                        .strokeBorder(Theme.ink.opacity(0.18), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(10)
        }
        .scaleEffect(isSelected ? 1.0 : 0.96)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }

    // MARK: - Step 2: Completion

    private var completionStep: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color(hex: "C2F542"))
                    .frame(width: 104, height: 104)
                    .shadow(color: Color(hex: "C2F542").opacity(0.45), radius: 24, x: 0, y: 10)
                Image(systemName: "checkmark")
                    .font(.system(size: 46, weight: .black))
                    .foregroundStyle(Theme.ink)
            }

            Spacer().frame(height: 32)

            VStack(spacing: 10) {
                Text("You're all set!")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text("Your daily quests are ready:")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer().frame(height: 28)

            // Selected categories list (single column so long names never truncate)
            VStack(spacing: 10) {
                ForEach(allSelected) { cat in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(cat.color)
                                .frame(width: 34, height: 34)
                            Image(systemName: cat.systemImageName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.ink.opacity(0.7))
                        }
                        Text(cat.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.accentGreen)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            Button {
                Task { await finish() }
            } label: {
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Start Leveling Up")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isSaving)
            .padding(.horizontal, 32)
            .padding(.bottom, 56)
        }
    }

    // MARK: - Finish

    private func finish() async {
        isSaving = true
        // Persist locally so the home screen can show categories without a backend round-trip
        UserDefaults.standard.set(allSelected.map(\.rawValue), forKey: "selectedCategoryIds")
        // Enable any optional categories the user picked on the backend
        await withTaskGroup(of: Void.self) { group in
            for cat in selectedOptional {
                group.addTask {
                    try? await ProfileAPI.shared.setCategoryEnabled(cat, enabled: true)
                }
            }
        }
        appState.hasCompletedOnboarding = true
    }
}
