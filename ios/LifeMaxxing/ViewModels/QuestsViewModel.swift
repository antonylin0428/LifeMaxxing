import Foundation
import Observation

@Observable
@MainActor
final class QuestsViewModel {
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

    /// Compares the server's lastCompletedDate (YYYY-MM-DD UTC) to today in
    /// UTC so the check matches the server's own day-boundary logic exactly.
    func isCompletedToday(_ category: CategoryStat) -> Bool {
        guard let last = category.lastCompletedDate else { return false }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let todayUTC = cal.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")!
        return last == formatter.string(from: todayUTC)
    }
}
