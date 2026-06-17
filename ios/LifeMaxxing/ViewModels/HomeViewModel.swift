import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var categories: [CategoryStat] = []
    var lastReward: CompleteTaskResult?
    var errorMessage: String?
    var isLoading = false

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            categories = try await ProfileAPI.shared.getCategories()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func complete(_ categoryId: CategoryId) async {
        errorMessage = nil
        do {
            // The client never computes XP/streak itself - it only ever
            // displays exactly what this server response says happened.
            lastReward = try await TasksAPI.shared.completeTask(categoryId: categoryId)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
