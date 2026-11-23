import Foundation
import SwiftUI

protocol BooksClient: Sendable {
    func search(_ query: String) async throws -> [Volume]
    func volume(id: String) async throws -> Volume
}

struct GoogleBooksClient: BooksClient {
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 2 * 1024 * 1024, diskCapacity: 10 * 1024 * 1024)
        config.requestCachePolicy = .useProtocolCachePolicy
        session = URLSession(configuration: config)
    }

    func search(_ query: String) async throws -> [Volume] {
        let response: VolumesResponse = try await fetch(
            path: "volumes",
            items: [URLQueryItem(name: "q", value: query),
                    URLQueryItem(name: "maxResults", value: "20"),
                    URLQueryItem(name: "printType", value: "books")])
        return response.items ?? []
    }

    func volume(id: String) async throws -> Volume {
        try await fetch(path: "volumes/\(id)", items: [])
    }

    private func fetch<T: Decodable>(path: String, items: [URLQueryItem]) async throws -> T {
        var components = URLComponents(url: APIConfig.baseURL.appending(path: path),
                                       resolvingAgainstBaseURL: false)!
        var query = items
        if let key = APIConfig.apiKey { query.append(URLQueryItem(name: "key", value: key)) }
        components.queryItems = query

        var request = URLRequest(url: components.url!)
        request.setValue(APIConfig.bundleID, forHTTPHeaderField: "X-Ios-Bundle-Identifier")

        let data: Data
        do {
            data = try await load(request)
        } catch let error as URLError where Self.offlineCodes.contains(error.code) {
            var cached = request
            cached.cachePolicy = .returnCacheDataDontLoad
            data = try await load(cached)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func load(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private static let offlineCodes: Set<URLError.Code> =
        [.notConnectedToInternet, .networkConnectionLost, .timedOut]
}

// MARK: - Environment

private struct BooksClientKey: EnvironmentKey {
    static let defaultValue: any BooksClient = GoogleBooksClient()
}

extension EnvironmentValues {
    var booksClient: any BooksClient {
        get { self[BooksClientKey.self] }
        set { self[BooksClientKey.self] = newValue }
    }
}
