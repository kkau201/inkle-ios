import Foundation

nonisolated struct VolumesResponse: Decodable, Sendable {
    let items: [Volume]?
}

nonisolated struct Volume: Decodable, Identifiable, Hashable, Sendable {
    let id: String
    let volumeInfo: VolumeInfo
}

nonisolated struct VolumeInfo: Decodable, Hashable, Sendable {
    var title: String?
    var authors: [String]?
    var publishedDate: String?
    var pageCount: Int?
    var categories: [String]?
    var description: String?
    var imageLinks: ImageLinks?

    struct ImageLinks: Decodable, Hashable, Sendable {
        var thumbnail: String?
    }

    var year: String? {
        guard let d = publishedDate, !d.isEmpty else { return nil }
        let prefix = d.prefix(4)
        return prefix.count == 4 && prefix.allSatisfy(\.isNumber) ? String(prefix) : d
    }

    var coverURL: URL? {
        guard let t = imageLinks?.thumbnail else { return nil }
        return URL(string: t.replacingOccurrences(of: "http://", with: "https://"))
    }

    var knownPageCount: Int? {
        guard let n = pageCount, n > 0 else { return nil }
        return n
    }

    var tags: [String] {
        var seen = Set<String>()
        var out: [String] = []
        for category in categories ?? [] {
            for part in category.split(separator: "/") {
                let tag = part.trimmingCharacters(in: .whitespaces)
                if !tag.isEmpty, seen.insert(tag).inserted { out.append(tag) }
            }
        }
        return out
    }
}
