import Foundation

/// Placeholder until there is a real profile.
enum UserProfile {
    static let name = "Reader"

    static var initials: String {
        String(name.split(separator: " ").prefix(2).compactMap(\.first)).uppercased()
    }
}
