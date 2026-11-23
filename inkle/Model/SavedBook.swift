import Foundation
import SwiftData

/// A book on the user's shelf. CloudKit-compatible: every property is optional or defaulted,
/// there is no `.unique` attribute and no required relationship.
@Model
final class SavedBook {
    static let maxAuthors = 10

    // From Google Books
    var volumeID: String = ""
    var title: String = ""
    var authors: [String] = []
    var pageCount: Int?

    // User data
    var startDate: Date?
    var finishedYear: Int?
    var finishedMonth: Int?
    var finishedDay: Int?
    var currentPage: Int?
    var rating: Int?
    var notes: String?
    var savedAt: Date = Date.now

    init(volume: Volume) {
        volumeID = volume.id
        title = volume.volumeInfo.title ?? "Untitled"
        authors = Array((volume.volumeInfo.authors ?? []).prefix(Self.maxAuthors))
        pageCount = volume.volumeInfo.knownPageCount
    }

    var finishedDate: PartialDate? {
        get { finishedYear.map { PartialDate(year: $0, month: finishedMonth, day: finishedDay) } }
        set {
            finishedYear = newValue?.year
            finishedMonth = newValue?.month
            finishedDay = newValue?.day
        }
    }

    /// Derived: no start → want to read; start and no finish → reading; both → finished.
    var status: ReadingStatus {
        if startDate == nil { return .wantToRead }
        return finishedDate == nil ? .reading : .finished
    }

    func setStatus(_ status: ReadingStatus, currentPage page: Int? = nil, finishedOn date: PartialDate? = nil) {
        switch status {
        case .wantToRead:
            startDate = nil
            finishedDate = nil
            currentPage = nil
            rating = nil
        case .reading:
            if startDate == nil { startDate = .now }
            finishedDate = nil
            if let page { currentPage = clampedPage(page) }
        case .finished:
            if startDate == nil { startDate = .now }
            finishedDate = date ?? .today
        }
    }

    private func clampedPage(_ page: Int) -> Int? {
        guard page > 0 else { return nil }
        return min(page, pageCount ?? page)
    }

    /// A minimal volume for the offline "saved copy" view: no cover, description or tags.
    var asVolume: Volume {
        Volume(id: volumeID, volumeInfo: VolumeInfo(
            title: title, authors: authors.isEmpty ? nil : authors, publishedDate: nil,
            pageCount: pageCount, categories: nil, description: nil, imageLinks: nil))
    }
}
