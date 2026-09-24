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
                    ForEach($viewModel.goals) { $goal in
                        goalRow(goal: goal)
                    }
                    .onDelete { viewModel.removeGoal(at: $0) }
                    .onMove { viewModel.moveGoal(from: $0, to: $1) }

                    Button {
                        viewModel.addGoal()
                        editingGoal = viewModel.goals.last
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(Theme.accentGreen)
                            Text("Add Goal")
                                .foregroundStyle(Theme.textPrimary)
                        }
                    }
                } header: {
                    Text("Community Goals")
                } footer: {
                    Text("Goals appear in order. Drag to reorder. Members complete each goal daily.")
                        .font(.system(size: 12))
                }

                if let err = viewModel.saveError {
                    Section {
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "FF4444"))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, .constant(.active))
        }
        .navigationTitle("Community Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Button("Save") { Task { await viewModel.save() } }
                        .font(.system(size: 15, weight: .semibold))
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

    private func goalRow(goal: CommunityGoalDraft) -> some View {
        Button { editingGoal = goal } label: {
            HStack(spacing: 12) {
                Text(goal.emoji)
                    .font(.system(size: 24))
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.name.isEmpty ? "Unnamed Goal" : goal.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(goal.name.isEmpty ? Theme.textSecondary : Theme.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: goal.trackingType == .photo ? "camera.fill"
                              : goal.trackingType == .text ? "text.bubble.fill"
                              : "camera.badge.plus")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textSecondary)
                        Text(goal.trackingType.displayName)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary.opacity(0.4))
            }
        }
        .buttonStyle(.plain)
    }
}
