import Foundation

struct ResponseCacheEntry: Sendable {
    let data: Data
    let expiryDate: Date?

    var isExpired: Bool {
        guard let expiryDate else { return false }
        return Date() >= expiryDate
    }
}

final class APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let memoryCache = LRUCache<String, ResponseCacheEntry>(capacity: 150)
    private let simulator: NetworkConditionSimulator

    init(
        baseURL: URL,
        session: URLSession? = nil,
        simulator: NetworkConditionSimulator = .shared
    ) {
        self.baseURL = baseURL
        self.simulator = simulator

        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.waitsForConnectivity = true
            configuration.requestCachePolicy = .useProtocolCachePolicy
            // URLCache keeps serialized responses across launches while LRU provides O(1) hot-path hits in memory.
            configuration.urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024, diskCapacity: 200 * 1024 * 1024)
            self.session = URLSession(configuration: configuration)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type = T.self) async throws -> T {
        let request = try makeRequest(for: endpoint)
        let data = try await requestData(endpoint: endpoint, request: request)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }

    func requestData(endpoint: Endpoint, request: URLRequest) async throws -> Data {
        let cacheKey = cacheKey(for: request)

        if endpoint.method == .get,
           endpoint.cachePolicy != .reloadIgnoringLocalCacheData,
           let cached = await memoryCache.value(for: cacheKey),
           !cached.isExpired {
            AppLoggers.networking.debug("Memory cache hit for \(request.url?.absoluteString ?? "unknown", privacy: .private(mask: .hash))")
            return cached.data
        }

        if endpoint.method == .get,
           endpoint.cachePolicy != .reloadIgnoringLocalCacheData,
           let cachedResponse = session.configuration.urlCache?.cachedResponse(for: request),
           let http = cachedResponse.response as? HTTPURLResponse,
           !isExpired(response: http) {
            AppLoggers.networking.debug("URLCache hit for \(request.url?.absoluteString ?? "unknown", privacy: .private(mask: .hash))")
            let expiry = expiryDate(from: http)
            await memoryCache.setValue(ResponseCacheEntry(data: cachedResponse.data, expiryDate: expiry), for: cacheKey)
            return cachedResponse.data
        }

        var lastError: Error?

        for attempt in 0...endpoint.retryCount {
            let interval = SignpostInterval(name: "APIRequest", message: "path=\(endpoint.path) attempt=\(attempt)")
            do {
                try await simulator.applySimulationIfNeeded()

                AppLoggers.networking.log(
                    level: .debug,
                    "HTTP \(request.httpMethod ?? "GET", privacy: .public) \(request.url?.absoluteString ?? "unknown", privacy: .private(mask: .hash))"
                )

                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }

                AppLoggers.networking.log(
                    level: .debug,
                    "HTTP status=\(http.statusCode, privacy: .public) bytes=\(data.count, privacy: .public)"
                )

                guard 200..<300 ~= http.statusCode else {
                    throw NetworkError.httpStatus(http.statusCode, data)
                }

                cache(data: data, response: http, request: request, cacheKey: cacheKey)

                interval.end(message: "success")
                return data
            } catch {
                interval.end(message: "error")
                lastError = error

                let shouldRetry = attempt < endpoint.retryCount && isRetryable(error)
                if shouldRetry {
                    let seconds = 0.3 * pow(2.0, Double(attempt))
                    // Exponential backoff prevents synchronized retry spikes under degraded network conditions.
                    try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                    continue
                }

                throw error
            }
        }

        throw lastError ?? NetworkError.invalidResponse
    }

    private func makeRequest(for endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = endpoint.queryItems.isEmpty ? nil : endpoint.queryItems

        guard let url = components.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        request.timeoutInterval = endpoint.timeout
        request.cachePolicy = endpoint.cachePolicy

        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }

    private func cache(data: Data, response: HTTPURLResponse, request: URLRequest, cacheKey: String) {
        guard request.httpMethod == HTTPMethod.get.rawValue else { return }
        guard shouldStoreResponse(response: response) else { return }

        let expiry = expiryDate(from: response)
        let entry = ResponseCacheEntry(data: data, expiryDate: expiry)

        Task {
            await memoryCache.setValue(entry, for: cacheKey)
        }

        if let urlCache = session.configuration.urlCache {
            let cachedResponse = CachedURLResponse(response: response, data: data)
            urlCache.storeCachedResponse(cachedResponse, for: request)
        }
    }

    private func cacheKey(for request: URLRequest) -> String {
        "\(request.httpMethod ?? "GET"):" + (request.url?.absoluteString ?? "")
    }

    private func isRetryable(_ error: Error) -> Bool {
        if case NetworkError.simulatedFailure = error {
            return true
        }

        if case NetworkError.httpStatus(let status, _) = error {
            return status >= 500
        }

        if let urlError = error as? URLError {
            return [.timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotFindHost].contains(urlError.code)
        }

        return false
    }

    private func shouldStoreResponse(response: HTTPURLResponse) -> Bool {
        let cacheControl = response.value(forHTTPHeaderField: "Cache-Control")?.lowercased() ?? ""

        if cacheControl.contains("no-store") {
            return false
        }

        return true
    }

    private func isExpired(response: HTTPURLResponse) -> Bool {
        guard let expiry = expiryDate(from: response) else { return false }
        return Date() >= expiry
    }

    private func expiryDate(from response: HTTPURLResponse) -> Date? {
        guard let cacheControl = response.value(forHTTPHeaderField: "Cache-Control")?.lowercased() else {
            return nil
        }

        if cacheControl.contains("no-cache") {
            return Date()
        }

        let directives = cacheControl.split(separator: ",")
        for directive in directives {
            let trimmed = directive.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("max-age="),
               let seconds = TimeInterval(trimmed.replacingOccurrences(of: "max-age=", with: "")) {
                return Date().addingTimeInterval(seconds)
            }
        }

        return nil
    }
}
