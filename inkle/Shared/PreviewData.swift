import Foundation

extension Volume {
    static func sample(id: String = "sample1", title: String = "Dune",
                       authors: [String] = ["Frank Herbert"]) -> Volume {
        Volume(id: id, volumeInfo: VolumeInfo(
            title: title, authors: authors, publishedDate: "1965-08-01", pageCount: 412,
            categories: ["Fiction / Science Fiction / Classics"], description: nil, imageLinks: nil))
    }
}

extension Volume {
    /// Has a cover, a formatted description and many categories.
    static let richSample = Volume(id: "rich", volumeInfo: VolumeInfo(
        title: "Dune", authors: ["Frank Herbert"], publishedDate: "1965-08-01", pageCount: 412,
        categories: ["Fiction / Science Fiction / Classics", "Fiction / Adventure", "Nature / Ecology"],
        description: "<p><b>Set on the desert planet Arrakis</b>, Dune is the story of the boy "
            + "<i>Paul Atreides</i>.</p><p>A masterpiece of science fiction.<br>Second line.</p>",
        imageLinks: .init(thumbnail: "http://books.google.com/books/content?id=B1hSG45JCX4C&printsec=frontcover&img=1&zoom=1")))

    /// No cover, no description, no categories and an unknown page count.
    static let bareSample = Volume(id: "bare", volumeInfo: VolumeInfo(
        title: "An Obscure Pamphlet", authors: nil, publishedDate: "c. 1890", pageCount: 0,
        categories: nil, description: nil, imageLinks: nil))
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
