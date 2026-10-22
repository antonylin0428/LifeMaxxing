import SwiftUI

struct CommunitySettingsView: View {
    let communityId: String
    @State private var viewModel: CommunitySettingsViewModel
    @State private var editingGoal: CommunityGoalDraft?

    init(communityId: String) {
        self.communityId = communityId
        _viewModel = State(initialValue: CommunitySettingsViewModel(communityId: communityId))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                Section {
                    headerText
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                    ForEach($viewModel.goals) { $goal in
                        goalRow(goal: goal)
                            .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .onDelete { viewModel.removeGoal(at: $0) }
                    .onMove { viewModel.moveGoal(from: $0, to: $1) }

                    addGoalRow
                        .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                    footerText
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                    if let err = viewModel.saveError {
                        ErrorBanner(message: err)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, .constant(.active))
        }
        .navigationTitle("Community Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isSaving {
                    Text("Saving…")
                        .font(Theme.font(16, .regular))
                        .foregroundStyle(Theme.textSecondary)
                } else {
                    Button("Save") { Task { await viewModel.save() } }
                        .font(Theme.font(16, .regular))
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .task { await viewModel.load() }
        .sheet(item: $editingGoal) { draft in
            CreateEditGoalView(draft: draft) { updated in
                if let idx = viewModel.goals.firstIndex(where: { $0.id == updated.id }) {
                    viewModel.goals[idx] = updated
                }
                editingGoal = nil
            } onCancel: {
                // Remove the goal if it was just created and has no name
                if let last = viewModel.goals.last, last.id == draft.id, last.name.isEmpty {
                    viewModel.goals.removeLast()
                }
                editingGoal = nil
            }
        }
        .onChange(of: viewModel.saveSuccess) { _, success in
            if success { /* could pop nav or show toast */ }
        }
    }

    // MARK: - Header / Footer / Add row
    // Plain List + .onMove/.onDelete keeps the native reorder handle and
    // swipe-to-delete (the right call on iOS - platform controls, not
    // reinvented ones), but every row below opts out of List's own
    // chrome (background, separators, section box) via listRow* modifiers
    // so it reads as this app's card stack, not a stock grouped list.

    private var headerText: some View {
        Text("Community Goals")
            .font(Theme.font(14))
            .foregroundStyle(Theme.textSecondary)
            .textCase(.uppercase)
            .tracking(0.8)
            .padding(.bottom, 2)
    }

    private var footerText: some View {
        Text("Goals appear in order. Drag to reorder. Members complete each goal daily.")
            .font(Theme.font(13))
            .foregroundStyle(Theme.textSecondary)
            .padding(.top, 2)
    }

    private var addGoalRow: some View {
        Button {
            viewModel.addGoal()
            editingGoal = viewModel.goals.last
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Theme.accent)
                Text("Add Goal")
                    .font(Theme.font(15, .regular))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }
            .padding(14)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .foregroundStyle(Theme.border)
            )
        }
        .buttonStyle(.plain)
    }

    private func goalRow(goal: CommunityGoalDraft) -> some View {
        Button { editingGoal = goal } label: {
            HStack(spacing: 12) {
                Text(goal.emoji)
                    .font(Theme.font(25))
                    .frame(width: 44, height: 44)
                    .background(Theme.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.name.isEmpty ? "Unnamed Goal" : goal.name)
                        .font(Theme.font(16, .regular))
                        .foregroundStyle(goal.name.isEmpty ? Theme.textSecondary : Theme.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: trackingIcon(goal.trackingType))
                            .font(Theme.font(11))
                            .foregroundStyle(Theme.textSecondary)
                        Text(goal.trackingType.displayName)
                            .font(Theme.font(12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Theme.font(13, .regular))
                    .foregroundStyle(Theme.textSecondary.opacity(0.4))
            }
            .padding(14)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func trackingIcon(_ type: CommunityGoal.TrackingType) -> String {
        switch type {
        case .photo: return "camera.fill"
        case .text: return "text.bubble.fill"
        case .both: return "camera.badge.plus"
        case .numeric: return "number"
        }
    }
}
