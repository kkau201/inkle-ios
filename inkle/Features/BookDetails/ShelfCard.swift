import SwiftUI

/// "On your shelf": status (changeable), progress, rating and notes.
struct ShelfCard: View {
    @Bindable var book: SavedBook

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("On your shelf").font(.headline)

            Menu {
                ForEach(ReadingStatus.allCases) { option in
                    Button {
                        book.setStatus(option)
                    } label: {
                        if book.status == option {
                            Label(option.label, systemImage: "checkmark")
                        } else {
                            Text(option.label)
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(book.status.label).fontWeight(.semibold)
                    if book.status == .finished, let date = book.finishedDate {
                        Text("· \(date.formatted)").foregroundStyle(.inkMuted)
                    }
                    Image(systemName: "chevron.up.chevron.down").font(.caption)
                }
            }
            .accessibilityHint("Change reading status")

            progress

            if let rating = book.rating, rating > 0 {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= rating ? "star.fill" : "star")
                            .foregroundStyle(.inkYellow)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Rated \(rating) out of 5")
            }

            if let notes = book.notes, !notes.isEmpty {
                Text(notes).font(.callout).foregroundStyle(.inkMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.inkCard, in: RoundedRectangle(cornerRadius: 12))
    }

    private var shownPage: Int? {
        book.status == .finished ? book.pageCount : book.currentPage
    }

    @ViewBuilder private var progress: some View {
        switch book.status {
        case .wantToRead:
            EmptyView()
        case .reading, .finished:
            if let total = book.pageCount, let page = shownPage {
                let fraction = min(Double(page) / Double(total), 1)
                VStack(alignment: .leading, spacing: 4) {
                    Text(fraction, format: .percent.precision(.fractionLength(0)))
                        .font(.subheadline.weight(.medium))
                    ProgressView(value: fraction)
                    Text("\(page) of \(total) pages").font(.caption).foregroundStyle(.inkMuted)
                }
                .accessibilityElement(children: .combine)
            } else if book.status == .reading, let page = book.currentPage {
                Text("You're on page \(page)").font(.subheadline)
            }
        }
    }
}
