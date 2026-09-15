import Foundation
import Observation

@Observable
@MainActor
final class ProfileViewModel {
    var user: User?
    var categories: [CategoryStat] = []
    var errorMessage: String?
    var isLoading = false

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

    #if DEBUG
    func setMockCommunityAccess(_ hasCommunityAccess: Bool) async {
        errorMessage = nil
        do {
            try await ProfileAPI.shared.setMockCommunityAccess(hasCommunityAccess)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    #endif
}
