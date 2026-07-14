import Foundation

struct CategoriesResponse: Decodable {
    let categories: [CategoryStat]
}

struct UpdateCategoryConfigRequest: Encodable {
    let enabled: Bool
}

struct SetMockPremiumRequest: Encodable {
    let isPremium: Bool
}

struct ProfileAPI {
    static let shared = ProfileAPI()

    func getMe() async throws -> User {
        try await APIClient.shared.request(path: "/me")
    }

    func getCategories() async throws -> [CategoryStat] {
        let response: CategoriesResponse = try await APIClient.shared.request(path: "/me/categories")
        return response.categories
    }

    func setCategoryEnabled(_ categoryId: CategoryId, enabled: Bool) async throws {
        let body = UpdateCategoryConfigRequest(enabled: enabled)
        let _: EmptyResponse = try await APIClient.shared.request(
            path: "/me/categories/\(categoryId.rawValue)",
            method: .put,
            body: body
        )
    }

    /// TESTING-ONLY: flips the mock premium flag with no payment behind it.
    /// See backend/lambdas/setMockPremium - remove once real payments exist.
    func setMockPremium(_ isPremium: Bool) async throws {
        let body = SetMockPremiumRequest(isPremium: isPremium)
        let _: EmptyResponse = try await APIClient.shared.request(path: "/me/premium", method: .put, body: body)
    }
}
