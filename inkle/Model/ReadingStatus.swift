import Foundation

enum ReadingStatus: String, CaseIterable, Identifiable, Hashable {
    case wantToRead, reading, finished

    var id: Self { self }

    var label: LocalizedStringResource {
        switch self {
        case .wantToRead: "Want to read"
        case .reading: "Reading"
        case .finished: "Finished"
        }
    }
}
