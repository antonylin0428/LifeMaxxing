import Foundation
import Observation

@Observable
@MainActor
final class UserProfileViewModel {
    var profile: PublicUserProfile?
    var isLoading = false
    var errorMessage: String?

    var achievements: [Achievement] {
        Achievement.fromServerGrants(profile?.achievements)
    }

    private let sub: String

    init(sub: String) {
        self.sub = sub
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            profile = try await ProfileAPI.shared.getUserProfile(sub: sub)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
