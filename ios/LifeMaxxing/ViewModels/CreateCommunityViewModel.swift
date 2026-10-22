import Foundation
import Observation

@Observable
@MainActor
final class CreateCommunityViewModel {
    var name = ""
    var description = ""
    var createdCommunity: Community?
    var errorMessage: String?
    var needsPurchase = false
    var isLoading = false

    func createCommunity() async {
        isLoading = true
        errorMessage = nil
        needsPurchase = false
        defer { isLoading = false }
        do {
            createdCommunity = try await CommunitiesAPI.shared.createCommunity(
                name: name,
                description: description.isEmpty ? nil : description
            )
        } catch APIError.server(403, _) {
            errorMessage = "You don't have a community-creation credit available."
            needsPurchase = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
