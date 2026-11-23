import Foundation
import Observation

@Observable
final class SearchViewModel {
    enum State {
        case idle, loading, results([Volume]), empty, failed(String)
    }

    var query = ""
    private(set) var state: State = .idle

    private let client: any BooksClient
    private var searchTask: Task<Void, Never>?
    private var lastQuery = ""

    init(client: any BooksClient) {
        self.client = client
    }

    func queryChanged() {
        searchTask?.cancel()
        let q = trimmed
        guard q.count >= 2 else {
            state = .idle
            return
        }
        searchTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await self?.run(q)
        }
    }

    func submit() {
        searchTask?.cancel()
        let q = trimmed
        guard q.count >= 2 else { return }
        searchTask = Task { [weak self] in await self?.run(q) }
    }

    func retry() {
        searchTask?.cancel()
        let q = lastQuery
        guard !q.isEmpty else { return }
        searchTask = Task { [weak self] in await self?.run(q) }
    }

    private var trimmed: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func run(_ q: String) async {
        lastQuery = q
        state = .loading
        do {
            let volumes = try await client.search(q)
            guard !Task.isCancelled else { return }
            state = volumes.isEmpty ? .empty : .results(volumes)
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(Self.message(for: error))
        }
    }

    private static func message(for error: Error) -> String {
        if let e = error as? URLError, e.code == .notConnectedToInternet || e.code == .networkConnectionLost {
            return "You appear to be offline."
        }
        return "Something went wrong while searching."
    }
}
