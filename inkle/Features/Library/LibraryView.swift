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
                Text("Hello, \(UserProfile.name)").font(.subheadline).foregroundStyle(.inkMuted)
                Text("Library").font(.largeTitle.bold())
                Text("\(books.count) books").font(.subheadline).foregroundStyle(.inkMuted)
            }
            Spacer()
            Text(UserProfile.initials)
                .font(.headline)
                .frame(width: 44, height: 44)
                .background(.inkYellow, in: Circle())
                .foregroundStyle(.inkInkBase)
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
                            .background(filter == option ? AnyShapeStyle(.inkInk) : AnyShapeStyle(.inkCover),
                                        in: Capsule())
                            .foregroundStyle(filter == option ? AnyShapeStyle(.inkOnInk) : AnyShapeStyle(.inkInk))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(filter == option ? .isSelected : [])
                }
            }
        }
    }

    private var shelfItems: [ShelfItem] {
        var books = filtered
        var items: [ShelfItem] = []
        // Under All, the first book being read is pulled out and placed first.
        if filter == .all, let i = books.firstIndex(where: { $0.status == .reading }) {
            items.append(ShelfItem(book: books.remove(at: i), kind: .cover))
        }
        return items + books.map { ShelfItem(book: $0, kind: .spine) }
    }

    private var grid: some View {
        ShelfView(items: shelfItems)
    }
}

#Preview("Empty") {
    NavigationStack { LibraryView() }
        .modelContainer(for: SavedBook.self, inMemory: true)
}

#Preview("Full shelf") {
    NavigationStack { LibraryView() }
        .modelContainer(PreviewData.container())
}
