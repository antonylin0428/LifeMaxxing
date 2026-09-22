import Foundation

struct CategoriesResponse: Decodable {
    let categories: [CategoryStat]
}

struct UpdateCategoryConfigRequest: Encodable {
    let enabled: Bool
}

struct SetMockCommunityAccessRequest: Encodable {
    let hasCommunityAccess: Bool
}

struct UpdateProfileRequest: Encodable {
    let username: String?
    let avatarKey: String?
}

struct AvatarUploadUrlResponse: Decodable {
    let uploadUrl: String
    let s3Key: String
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

    func updateProfile(username: String? = nil, avatarKey: String? = nil) async throws {
        let body = UpdateProfileRequest(username: username, avatarKey: avatarKey)
        let _: EmptyResponse = try await APIClient.shared.request(path: "/me/profile", method: .put, body: body)
    }

    func getAvatarUploadUrl() async throws -> AvatarUploadUrlResponse {
        try await APIClient.shared.request(path: "/me/avatar-upload-url")
    }

    func uploadAvatar(_ data: Data, to uploadUrl: String) async throws {
        guard let url = URL(string: uploadUrl) else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await URLSession.shared.upload(for: request, from: data)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    func getUserProfile(sub: String) async throws -> PublicUserProfile {
        try await APIClient.shared.request(path: "/users/\(sub)")
    }

    #if DEBUG
    func setMockCommunityAccess(_ hasCommunityAccess: Bool) async throws {
        let body = SetMockCommunityAccessRequest(hasCommunityAccess: hasCommunityAccess)
        let _: EmptyResponse = try await APIClient.shared.request(path: "/me/premium", method: .put, body: body)
    }
    #endif
}
