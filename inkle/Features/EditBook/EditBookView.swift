import SwiftData
import SwiftUI

/// Local copy of the editable fields; nothing touches the book until Save.
struct BookDraft {
    var status: ReadingStatus
    var pageText: String
    var finished: PartialDate
    var rating: Int
    var notes: String

    init(book: SavedBook) {
        status = book.status
        pageText = book.currentPage.map(String.init) ?? ""
        finished = book.finishedDate ?? .today
        rating = book.rating ?? 0
        notes = book.notes ?? ""
    }

    func apply(to book: SavedBook) {
        switch status {
        case .wantToRead:
            book.setStatus(.wantToRead)
        case .reading:
            book.setStatus(.reading, currentPage: Int(pageText))
            if Int(pageText) == nil { book.currentPage = nil }
        case .finished:
            book.setStatus(.finished, finishedOn: finished)
            book.rating = rating > 0 ? rating : nil
        }
        book.notes = notes.isEmpty ? nil : notes
    }
}

struct EditBookView: View {
    static let notesLimit = 1000

    let book: SavedBook

    @Environment(\.dismiss) private var dismiss
    @State private var draft: BookDraft

    init(book: SavedBook) {
        self.book = book
        _draft = State(initialValue: BookDraft(book: book))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(book.title).font(.headline)
                }
                Section("Status") {
                    HStack(spacing: 8) {
                        ForEach(ReadingStatus.allCases) { option in
                            Button { draft.status = option } label: {
                                Text(option.label)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(draft.status == option ? AnyShapeStyle(.inkInk) : AnyShapeStyle(.inkCover),
                                                in: Capsule())
                                    .foregroundStyle(draft.status == option ? AnyShapeStyle(.inkOnInk) : AnyShapeStyle(.inkInk))
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(draft.status == option ? .isSelected : [])
                        }
                    }
                }
                if draft.status == .reading {
                    Section {
                        TextField("Page you're on", text: $draft.pageText)
                            .keyboardType(.numberPad)
                            .onChange(of: draft.pageText) { sanitizePage() }
                    } footer: {
                        if let count = book.pageCount { Text("This book has \(count) pages.") }
                    }
                }
                if draft.status == .finished {
                    Section("Finished on") { PartialDatePicker(date: $draft.finished) }
                    Section("Rating") { StarRating(rating: $draft.rating) }
                }
                Section {
                    TextEditor(text: $draft.notes)
                        .frame(minHeight: 120)
                        .onChange(of: draft.notes) {
                            if draft.notes.count > Self.notesLimit {
                                draft.notes = String(draft.notes.prefix(Self.notesLimit))
                            }
                        }
                        .accessibilityLabel("Notes")
                } header: {
                    Text("Notes")
                } footer: {
                    Text("\(draft.notes.count) / \(Self.notesLimit)")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .navigationTitle("Edit book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        draft.apply(to: book)
                        dismiss()
                    }
                }
            }
        }
    }

    private func sanitizePage() {
        var digits = draft.pageText.filter(\.isNumber)
        if let count = book.pageCount, let n = Int(digits), n > count { digits = String(count) }
        if digits != draft.pageText { draft.pageText = digits }
    }
}

/// 1–5 stars; tapping the current rating clears it.
private struct StarRating: View {
    @Binding var rating: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    rating = rating == star ? 0 : star
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundStyle(.inkYellow)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(star) \(star == 1 ? "star" : "stars")")
                .accessibilityAddTraits(star == rating ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview("Finished") {
    let container = PreviewData.container()
    let book = try! container.mainContext.fetch(FetchDescriptor<SavedBook>())
        .first { $0.status == .finished }!
    return EditBookView(book: book).modelContainer(container)
}

#Preview("Reading") {
    let container = PreviewData.container()
    let book = try! container.mainContext.fetch(FetchDescriptor<SavedBook>())
        .first { $0.status == .reading }!
    return EditBookView(book: book).modelContainer(container)
}
