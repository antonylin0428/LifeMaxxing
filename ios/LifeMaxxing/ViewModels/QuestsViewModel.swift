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
            let serverStats = try await ProfileAPI.shared.getCategories()
            let serverMap = Dictionary(uniqueKeysWithValues: serverStats.map { ($0.categoryId, $0) })
            // Show every category regardless of whether the server has a stats row yet.
            // Categories explicitly disabled (enabled == false) are hidden.
            categories = CategoryId.allCases.compactMap { catId in
                if let stat = serverMap[catId] {
                    return stat.enabled == false ? nil : stat
                }
                return CategoryStat(
                    categoryId: catId,
                    currentStreak: 0,
                    longestStreak: 0,
                    lastCompletedDate: nil,
                    multiplierCache: nil,
                    freezesAvailable: 1,
                    enabled: nil
                )
            }
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
