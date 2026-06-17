import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum APIError: Error {
    case unauthorized
    case server(statusCode: Int, message: String?)
    case decoding(Error)
}

/// Thin authenticated networking layer. Every backend call in the app goes
/// through here so token attachment happens in exactly one place.
struct APIClient {
    static let shared = APIClient()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }()

    private let encoder = JSONEncoder()

    func request<Response: Decodable>(
        path: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil
    ) async throws -> Response {
        guard let url = URL(string: path, relativeTo: Constants.apiBaseURL) else {
            throw APIError.server(statusCode: -1, message: "Invalid path: \(path)")
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let accessToken = try await AuthService.shared.currentAccessToken()
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        if let body {
            urlRequest.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.server(statusCode: -1, message: "No HTTP response")
        }

        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw APIError.decoding(error)
            }
        case 401:
            throw APIError.unauthorized
        default:
            let message = String(data: data, encoding: .utf8)
            throw APIError.server(statusCode: httpResponse.statusCode, message: message)
        }
    }
}
