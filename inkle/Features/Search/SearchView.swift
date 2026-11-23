import SwiftUI

struct SearchView: View {
    @Environment(\.booksClient) private var client
    @State private var model: SearchViewModel?

    var body: some View {
        // The view model lives in @State at the tab root so it survives pushes.
        let model = model ?? SearchViewModel(client: client)
        SearchContent(model: model)
            .onAppear { if self.model == nil { self.model = model } }
    }
}

private struct SearchContent: View {
    @Bindable var model: SearchViewModel

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Search")
                .searchable(text: $model.query, prompt: "Title or author")
                .onChange(of: model.query) { model.queryChanged() }
                .onSubmit(of: .search) { model.submit() }
                .navigationDestination(for: BookRoute.self) { route in
                    BookDetailsView(volumeID: route.volumeID)
                }
        }
    }

    @ViewBuilder private var content: some View {
        switch model.state {
        case .idle:
            EmptyStateView(symbol: "books.vertical", title: "Browse the stacks",
                           message: "Look up any book and save it to your shelf.")
        case .loading:
            ProgressView()
        case .empty:
            EmptyStateView(symbol: "magnifyingglass", title: "No results",
                           message: "Try a different title or author.")
        case .failed(let message):
            ContentUnavailableView {
                Label("Couldn't search", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Try again") { model.retry() }
            }
        case .results(let volumes):
            List(volumes) { volume in
                NavigationLink(value: BookRoute(volumeID: volume.id)) {
                    SearchRow(volume: volume)
                }
            }
            .listStyle(.plain)
        }
    }
}

#Preview("Results") {
    SearchView().environment(\.booksClient, StubBooksClient())
}

#Preview("Offline") {
    SearchView().environment(\.booksClient, StubBooksClient(error: URLError(.notConnectedToInternet)))
}
