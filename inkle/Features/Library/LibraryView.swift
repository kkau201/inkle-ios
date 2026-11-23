import SwiftData
import SwiftUI

private enum LibraryFilter: CaseIterable, Identifiable {
    case all, wantToRead, reading, finished

    var id: Self { self }

    var status: ReadingStatus? {
        switch self {
        case .all: nil
        case .wantToRead: .wantToRead
        case .reading: .reading
        case .finished: .finished
        }
    }

    var label: LocalizedStringResource {
        status?.label ?? "All"
    }
}

struct LibraryView: View {
    @Query(sort: \SavedBook.savedAt) private var books: [SavedBook]
    @State private var filter: LibraryFilter = .all

    private var filtered: [SavedBook] {
        guard let status = filter.status else { return books }
        return books.filter { $0.status == status }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                if books.isEmpty {
                    EmptyStateView(symbol: "books.vertical",
                                   title: "Dust settled in",
                                   message: "Books you save will gather here.")
                } else {
                    chips
                    Text(filter == .all ? LocalizedStringResource("Your shelf") : filter.label)
                        .font(.title3.bold())
                    if filtered.isEmpty {
                        EmptyStateView(symbol: "books.vertical",
                                       title: "Getting a wee bit dusty in here…",
                                       message: "Nothing on this shelf yet.")
                    } else {
                        grid
                    }
                }
            }
            .padding()
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hello, \(UserProfile.name)").font(.subheadline).foregroundStyle(.secondary)
                Text("Library").font(.largeTitle.bold())
                Text("\(books.count) books").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Text(UserProfile.initials)
                .font(.headline)
                .frame(width: 44, height: 44)
                .background(.tint.opacity(0.2), in: Circle())
                .accessibilityHidden(true)
        }
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LibraryFilter.allCases) { option in
                    Button { filter = option } label: {
                        Text(option.label)
                            .font(.subheadline)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(filter == option ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary.opacity(0.15)),
                                        in: Capsule())
                            .foregroundStyle(filter == option ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(filter == option ? .isSelected : [])
                }
            }
        }
    }

    // Temporary layout; step 4 replaces it with the wooden shelf.
    private var grid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 10)], spacing: 10) {
            ForEach(filtered) { book in
                NavigationLink(value: BookRoute(volumeID: book.volumeID)) {
                    Text(book.title)
                        .font(.caption.bold())
                        .foregroundStyle(.black.opacity(0.8))
                        .lineLimit(5)
                        .multilineTextAlignment(.leading)
                        .padding(8)
                        .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                        .background(BookAppearance(volumeID: book.volumeID).color,
                                    in: RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview("Empty") {
    NavigationStack { LibraryView() }
        .modelContainer(for: SavedBook.self, inMemory: true)
}
