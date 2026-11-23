import SwiftData
import SwiftUI

struct BookDetailsView: View {
    let volumeID: String

    @Environment(\.booksClient) private var client
    @Environment(ConnectivityMonitor.self) private var monitor
    @State private var model: BookDetailsViewModel?
    @Query private var saved: [SavedBook]

    init(volumeID: String) {
        self.volumeID = volumeID
        _saved = Query(filter: #Predicate<SavedBook> { $0.volumeID == volumeID })
    }

    var body: some View {
        Group {
            if let model {
                BookDetailsContent(model: model, saved: saved.first)
            } else {
                Color.clear
            }
        }
        .task {
            if model == nil { model = BookDetailsViewModel(volumeID: volumeID, client: client) }
            await model?.load()
        }
        .onChange(of: monitor.isConnected) { _, connected in
            if connected { Task { await model?.load() } }
        }
    }
}

private struct BookDetailsContent: View {
    @Bindable var model: BookDetailsViewModel
    let saved: SavedBook?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showAddSheet = false
    @State private var confirmRemove = false
    @State private var showEdit = false

    /// The loaded volume, or on failure the saved copy (no cover, description or tags).
    private var displayed: Volume? {
        switch model.phase {
        case .loaded(let volume): return volume
        case .failed: return saved?.asVolume
        case .loading: return nil
        }
    }

    private var isShowingSavedCopy: Bool {
        if case .failed = model.phase { return saved != nil }
        return false
    }

    var body: some View {
        Group {
            if let volume = displayed {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if isShowingSavedCopy {
                            Label("Showing your saved copy", systemImage: "icloud.slash")
                                .font(.footnote)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.inkOrange.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
                        }
                        Heading(volumeID: volume.id, info: volume.volumeInfo)
                        if let saved { ShelfCard(book: saved) }
                        if !volume.volumeInfo.tags.isEmpty {
                            TagChips(tags: volume.volumeInfo.tags)
                        }
                        if let about = model.about {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("About").font(.headline)
                                Text(about)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if case .loading = model.phase {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Color.clear
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if saved != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { showEdit = true }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Remove", role: .destructive) { confirmRemove = true }
                }
            } else if case .loaded = model.phase {
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") { showAddSheet = true }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            if case .loaded(let volume) = model.phase { AddToShelfSheet(volume: volume) }
        }
        .sheet(isPresented: $showEdit) {
            if let saved { EditBookView(book: saved) }
        }
        .confirmationDialog("Remove book?", isPresented: $confirmRemove, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                if let saved { modelContext.delete(saved) }
            }
        } message: {
            Text("It will be taken off your shelf, along with your notes and rating.")
        }
        // A failed load only alerts when there is no saved copy to fall back on.
        .alert("Couldn't load this book",
               isPresented: Binding(get: { model.showError && saved == nil },
                                    set: { model.showError = $0 })) {
            Button("OK") { dismiss() }
        } message: {
            Text("Check your connection and try again.")
        }
    }
}

private struct Heading: View {
    let volumeID: String
    let info: VolumeInfo

    var body: some View {
        let appearance = BookAppearance(volumeID: volumeID)
        HStack(alignment: .top, spacing: 16) {
            // The spine colour shows while the cover loads, if it fails, and when there is no URL.
            ZStack {
                appearance.color
                AsyncImage(url: info.coverURL) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    }
                }
            }
            .frame(width: 110, height: 165)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(radius: 3, y: 2)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(info.title ?? "Untitled").font(.title2.bold())
                if let authors = info.authors, !authors.isEmpty {
                    Text(authors.joined(separator: ", ")).font(.subheadline).foregroundStyle(.inkMuted)
                }
                if !meta.isEmpty {
                    Text(meta).font(.subheadline).foregroundStyle(.inkMuted)
                }
            }
        }
    }

    private var meta: String {
        let pages = info.knownPageCount.map { $0 == 1 ? "1 page" : "\($0) pages" }
        return [info.year, pages].compactMap { $0 }.joined(separator: " · ")
    }
}

#Preview("Cover, many tags") {
    NavigationStack { BookDetailsView(volumeID: "rich") }
        .environment(\.booksClient, StubBooksClient(results: [.richSample]))
        .environment(ConnectivityMonitor())
        .modelContainer(for: SavedBook.self, inMemory: true)
}

#Preview("No cover, no tags") {
    NavigationStack { BookDetailsView(volumeID: "bare") }
        .environment(\.booksClient, StubBooksClient(results: [.bareSample]))
        .environment(ConnectivityMonitor())
        .modelContainer(for: SavedBook.self, inMemory: true)
}

#Preview("Load fails") {
    NavigationStack { BookDetailsView(volumeID: "rich") }
        .environment(\.booksClient, StubBooksClient(error: URLError(.notConnectedToInternet)))
        .environment(ConnectivityMonitor())
        .modelContainer(for: SavedBook.self, inMemory: true)
}

#Preview("Saved") {
    NavigationStack { BookDetailsView(volumeID: "rich") }
        .environment(\.booksClient, StubBooksClient(results: [.richSample]))
        .environment(ConnectivityMonitor())
        .modelContainer(PreviewData.container())
}
