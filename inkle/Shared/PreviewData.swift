import Foundation

extension Volume {
    static func sample(id: String = "sample1", title: String = "Dune",
                       authors: [String] = ["Frank Herbert"]) -> Volume {
        Volume(id: id, volumeInfo: VolumeInfo(
            title: title, authors: authors, publishedDate: "1965-08-01", pageCount: 412,
            categories: ["Fiction / Science Fiction / Classics"], description: nil, imageLinks: nil))
    }
}

struct StubBooksClient: BooksClient {
    var results: [Volume] = [.sample(), .sample(id: "sample2", title: "Children of Dune")]
    var error: URLError?
    var delay: Duration = .zero

    func search(_ query: String) async throws -> [Volume] {
        try await Task.sleep(for: delay)
        if let error { throw error }
        return results
    }

    func volume(id: String) async throws -> Volume {
        if let error { throw error }
        return results.first { $0.id == id } ?? .sample(id: id)
    }
}
