import SwiftUI

struct BookDetailsView: View {
    let volumeID: String

    @Environment(\.booksClient) private var client
    @State private var model: BookDetailsViewModel?

    var body: some View {
        Group {
            if let model {
                BookDetailsContent(model: model)
            } else {
                Color.clear
            }
        }
        .task {
            if model == nil { model = BookDetailsViewModel(volumeID: volumeID, client: client) }
            await model?.load()
        }
    }
}

private struct BookDetailsContent: View {
    @Bindable var model: BookDetailsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            switch model.phase {
            case .loading:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed:
                Color.clear
            case .loaded(let volume):
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Heading(volumeID: volume.id, info: volume.volumeInfo)
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
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // Step 3 puts Save / Remove / Edit in the top bar.
        .alert("Couldn't load this book", isPresented: $model.showError) {
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
                    Text(authors.joined(separator: ", ")).font(.subheadline).foregroundStyle(.secondary)
                }
                if !meta.isEmpty {
                    Text(meta).font(.subheadline).foregroundStyle(.secondary)
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
}

#Preview("No cover, no tags") {
    NavigationStack { BookDetailsView(volumeID: "bare") }
        .environment(\.booksClient, StubBooksClient(results: [.bareSample]))
}

#Preview("Load fails") {
    NavigationStack { BookDetailsView(volumeID: "rich") }
        .environment(\.booksClient, StubBooksClient(error: URLError(.notConnectedToInternet)))
}
