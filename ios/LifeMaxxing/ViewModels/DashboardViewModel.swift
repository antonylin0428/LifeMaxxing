import Foundation
import Observation

@Observable
@MainActor
final class DashboardViewModel {
    var user: User?
    var categories: [CategoryStat] = []
    var errorMessage: String?
    var isLoading = false

    /// Achievements are local mock data only - see Achievement.swift.
    let achievements = Achievement.mockForPrototype

    /// The dashboard shows one streak badge, but streaks are tracked
    /// per-category server-side. Surface the best currently-active streak.
    var bestCurrentStreak: Int {
        categories.map(\.currentStreak).max() ?? 0
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let userFetch = ProfileAPI.shared.getMe()
            async let categoriesFetch = ProfileAPI.shared.getCategories()
            user = try await userFetch
            categories = try await categoriesFetch
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isCompletedToday(_ category: CategoryStat) -> Bool {
        guard let lastCompletedDate = category.lastCompletedDate else { return false }
        return lastCompletedDate == Self.todayDateString
    }

    private static var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: Date())
    }
}
