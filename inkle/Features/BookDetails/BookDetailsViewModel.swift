import Foundation
import Observation

@Observable
final class BookDetailsViewModel {
    enum Phase {
        case loading
        case loaded(Volume)
        case failed
    }

    let volumeID: String
    private let client: any BooksClient

    private(set) var phase: Phase = .loading
    /// The description converted from HTML once, at load time, rather than in `body`.
    private(set) var about: AttributedString?
    var showError = false

    init(volumeID: String, client: any BooksClient) {
        self.volumeID = volumeID
        self.client = client
    }

    func load() async {
        if case .loaded = phase { return }
        phase = .loading
        do {
            let volume = try await client.volume(id: volumeID)
            about = volume.volumeInfo.description.flatMap(HTMLText.attributedString(from:))
            phase = .loaded(volume)
        } catch {
            if Task.isCancelled || (error as? URLError)?.code == .cancelled { return }
            phase = .failed
            showError = true
        }
    }
}
