import Foundation
import Observation

@Observable
@MainActor
final class CommunitySettingsViewModel {
    var goals: [CommunityGoalDraft] = []
    var isSaving = false
    var isLoading = false
    var saveError: String?
    var saveSuccess = false

    private let communityId: String

    init(communityId: String) {
        self.communityId = communityId
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        if let fetched = try? await CommunitiesAPI.shared.getCommunityGoals(id: communityId) {
            goals = fetched.map { CommunityGoalDraft(from: $0) }
        }
    }

    func addGoal() {
        var draft = CommunityGoalDraft()
        draft.order = goals.count
        goals.append(draft)
    }

    func removeGoal(at offsets: IndexSet) {
        goals.remove(atOffsets: offsets)
    }

    func moveGoal(from source: IndexSet, to destination: Int) {
        goals.move(fromOffsets: source, toOffset: destination)
    }

    func save() async {
        isSaving = true
        saveError = nil
        saveSuccess = false
        defer { isSaving = false }
        do {
            let updated = try await CommunitiesAPI.shared.updateCommunityGoals(
                id: communityId, goals: goals)
            goals = updated.map { CommunityGoalDraft(from: $0) }
            saveSuccess = true
        } catch {
            saveError = error.localizedDescription
        }
    }
}
