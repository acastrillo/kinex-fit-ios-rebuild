import Foundation

/// Thread-safe API client with automatic JWT token refresh.
///
/// Uses Swift's `actor` for thread safety, especially around concurrent
/// token refresh coalescing — if multiple requests hit a 401 simultaneously,
/// only one refresh call is made.
actor APIClient {
    private let session: URLSession
    private let baseURL: URL
    private let tokenStore: TokenStore

    private var isRefreshing = false
    private var pendingContinuations: [CheckedContinuation<Void, Error>] = []

    init(tokenStore: TokenStore, baseURL: URL, session: URLSession = .shared) {
        self.tokenStore = tokenStore
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Public API

    /// Sends an API request and decodes the response.
    func send<T: Decodable>(_ request: APIRequest) async throws -> T {
        let data = try await performRequest(request)
        do {
            return try JSONDecoder.apiDecoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Sends an API request that returns no meaningful body (e.g., DELETE).
    func sendNoContent(_ request: APIRequest) async throws {
        _ = try await performRequest(request)
    }

    /// Sends a multipart form data request (e.g., image upload).
    func sendMultipart<T: Decodable>(_ multipart: MultipartFormData, path: String) async throws -> T {
        let boundary = multipart.boundary
        let request = APIRequest(
            method: .post,
            path: path,
            body: multipart.build(),
            contentType: .multipartFormData(boundary: boundary)
        )
        let data = try await performRequest(request)
        do {
            return try JSONDecoder.apiDecoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Private

    private func performRequest(_ request: APIRequest, isRetry: Bool = false) async throws -> Data {
        var urlRequest = try request.asURLRequest(baseURL: baseURL)

        // Attach bearer token
        if let accessToken = tokenStore.accessToken {
            urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Handle 401: attempt token refresh exactly once
        if httpResponse.statusCode == 401 && !isRetry {
            try await refreshTokenIfNeeded()
            return try await performRequest(request, isRetry: true)
        }

        // Handle other error status codes
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        return data
    }

    /// Coalesces concurrent refresh attempts into a single network call.
    /// If a refresh is already in-flight, subsequent callers wait for it.
    private func refreshTokenIfNeeded() async throws {
        if isRefreshing {
            // Wait for the in-flight refresh to complete
            try await withCheckedThrowingContinuation { continuation in
                pendingContinuations.append(continuation)
            }
            return
        }

        isRefreshing = true

        do {
            try await performTokenRefresh()
            // Resume all waiting continuations
            let waiting = pendingContinuations
            pendingContinuations = []
            isRefreshing = false
            for continuation in waiting {
                continuation.resume()
            }
        } catch {
            // Resume all waiting continuations with the error
            let waiting = pendingContinuations
            pendingContinuations = []
            isRefreshing = false
            for continuation in waiting {
                continuation.resume(throwing: error)
            }
            throw error
        }
    }

    private func performTokenRefresh() async throws {
        guard let refreshToken = tokenStore.refreshToken else {
            tokenStore.clearTokens()
            throw APIError.unauthorized
        }

        let body = try JSONEncoder().encode(["refreshToken": refreshToken])
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("/api/mobile/auth/refresh"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = body

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            tokenStore.clearTokens()
            throw APIError.unauthorized
        }

        let tokens = try JSONDecoder.apiDecoder.decode(TokenPair.self, from: data)
        tokenStore.save(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken)
    }
}

// MARK: - Token Response Model

struct TokenPair: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
}

/// Empty response type for endpoints that return no body.
struct EmptyResponse: Decodable, Sendable {}
