import Foundation
import Observation

@Observable
@MainActor
final class CreateCommunityViewModel {
    var name = ""
    var description = ""
    var createdCommunity: Community?
    var errorMessage: String?
    var isLoading = false

    func createCommunity() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            createdCommunity = try await CommunitiesAPI.shared.createCommunity(
                name: name,
                description: description.isEmpty ? nil : description
            )
        } catch APIError.server(403, _) {
            errorMessage = "Creating communities requires a premium account."
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
