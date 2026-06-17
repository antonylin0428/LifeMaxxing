import Foundation
import Observation

@Observable
@MainActor
final class LeaderboardViewModel {
    var entries: [LeaderboardEntry] = []
    var errorMessage: String?
    var isLoading = false

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            entries = try await FriendsAPI.shared.leaderboard()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
