import Foundation

struct UploadUrlResponse: Decodable {
    let uploadUrl: String
    let s3Key: String
}

struct FeedAPI {
    static let shared = FeedAPI()

    func getUploadUrl() async throws -> UploadUrlResponse {
        return try await APIClient.shared.request(path: "/tasks/upload-url", method: .get)
    }

    func uploadPhoto(_ data: Data, to uploadUrl: String) async throws {
        guard let url = URL(string: uploadUrl) else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        let (_, response) = try await URLSession.shared.upload(for: request, from: data)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    func getFriendsFeed() async throws -> [FeedPost] {
        return try await APIClient.shared.request(path: "/feed/friends", method: .get)
    }
}
