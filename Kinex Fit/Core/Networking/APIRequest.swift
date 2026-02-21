import Foundation

/// Describes an API request that can be sent by `APIClient`.
struct APIRequest: Sendable {
    let method: HTTPMethod
    let path: String
    let queryItems: [URLQueryItem]?
    let body: Data?
    let contentType: ContentType

    init(
        method: HTTPMethod = .get,
        path: String,
        queryItems: [URLQueryItem]? = nil,
        body: Data? = nil,
        contentType: ContentType = .json
    ) {
        self.method = method
        self.path = path
        self.queryItems = queryItems
        self.body = body
        self.contentType = contentType
    }

    /// Builds a `URLRequest` from this API request.
    func asURLRequest(baseURL: URL) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body

        switch contentType {
        case .json:
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        case .multipartFormData(let boundary):
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        case .none:
            break
        }

        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return request
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Content Type

enum ContentType: Sendable {
    case json
    case multipartFormData(boundary: String)
    case none
}

// MARK: - JSON Request Helpers

extension APIRequest {
    /// Creates a POST request with a JSON-encodable body.
    static func post<T: Encodable>(_ path: String, body: T) throws -> APIRequest {
        let data = try JSONEncoder.apiEncoder.encode(body)
        return APIRequest(method: .post, path: path, body: data)
    }

    /// Creates a PUT request with a JSON-encodable body.
    static func put<T: Encodable>(_ path: String, body: T) throws -> APIRequest {
        let data = try JSONEncoder.apiEncoder.encode(body)
        return APIRequest(method: .put, path: path, body: data)
    }

    /// Creates a PATCH request with a JSON-encodable body.
    static func patch<T: Encodable>(_ path: String, body: T) throws -> APIRequest {
        let data = try JSONEncoder.apiEncoder.encode(body)
        return APIRequest(method: .patch, path: path, body: data)
    }

    /// Creates a GET request.
    static func get(_ path: String, queryItems: [URLQueryItem]? = nil) -> APIRequest {
        APIRequest(method: .get, path: path, queryItems: queryItems)
    }

    /// Creates a DELETE request.
    static func delete(_ path: String) -> APIRequest {
        APIRequest(method: .delete, path: path, contentType: .none)
    }
}

// MARK: - JSON Coders

extension JSONEncoder {
    static let apiEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
}

extension JSONDecoder {
    static let apiDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}
