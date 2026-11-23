import Foundation

nonisolated enum APIConfig {
    static let baseURL = URL(string: "https://www.googleapis.com/books/v1")!

    /// Empty when no key is configured; requests then use the keyless quota.
    static var apiKey: String? {
        let key = (Bundle.main.object(forInfoDictionaryKey: "GoogleBooksAPIKey") as? String)?
            .trimmingCharacters(in: .whitespaces)
        guard let key, !key.isEmpty, !key.hasPrefix("$(") else { return nil }
        return key
    }

    static var bundleID: String { Bundle.main.bundleIdentifier ?? "" }
}
