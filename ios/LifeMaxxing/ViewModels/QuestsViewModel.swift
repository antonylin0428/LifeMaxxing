import Foundation
import Observation

@Observable
@MainActor
final class QuestsViewModel {
    var categories: [CategoryStat] = []
    var communities: [Community] = []
    var lastReward: CompleteTaskResult?
    var errorMessage: String?
    var isLoading = false

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let categoriesTask = ProfileAPI.shared.getCategories()
            async let communitiesTask = CommunitiesAPI.shared.listMyCommunities()
            let serverStats = try await categoriesTask
            // Communities isn't load-bearing for the quest list itself, so a
            // failure here (e.g. offline) shouldn't block the rest of the tab.
            communities = (try? await communitiesTask) ?? []

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
                    enabled: nil,
                    categoryXPToday: nil
                )
            }
        } catch {
            if error.isCancellation { return }
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

    /// Compares the server's lastCompletedDate (YYYY-MM-DD in the user's own
    /// timezone) to today in that same local timezone, matching the server's
    /// day-boundary logic exactly.
    func isCompletedToday(_ category: CategoryStat) -> Bool {
        guard let last = category.lastCompletedDate else { return false }
        return last == Date().localDayString
    }
}
