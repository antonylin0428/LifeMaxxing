import Foundation

struct CompleteTaskRequest: Encodable {
    let categoryId: String
    let idempotencyKey: String
}

struct UseStreakFreezeRequest: Encodable {
    let categoryId: String
}

struct TasksAPI {
    static let shared = TasksAPI()

    func completeTask(categoryId: CategoryId) async throws -> CompleteTaskResult {
        let body = CompleteTaskRequest(categoryId: categoryId.rawValue, idempotencyKey: UUID().uuidString)
        return try await APIClient.shared.request(path: "/tasks/complete", method: .post, body: body)
    }

    func useStreakFreeze(categoryId: CategoryId) async throws {
        let body = UseStreakFreezeRequest(categoryId: categoryId.rawValue)
        let _: EmptyResponse = try await APIClient.shared.request(path: "/tasks/freeze", method: .post, body: body)
    }
}

/// Decodes any JSON object body when the caller doesn't need the fields.
struct EmptyResponse: Decodable {}
