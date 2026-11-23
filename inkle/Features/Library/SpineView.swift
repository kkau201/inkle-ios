import SwiftUI

/// A book standing on the shelf: colour fill and a vertical title.
struct SpineView: View {
    let book: SavedBook

    var body: some View {
        let a = BookAppearance(volumeID: book.volumeID)
        ZStack {
            a.color
            Text(book.title)
                .font(.caption.bold())
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .foregroundStyle(.inkInkBase)
                .frame(width: a.spineHeight - 16, height: a.spineWidth - 8)
                .rotationEffect(.degrees(-90))
        }
        .frame(width: a.spineWidth, height: a.spineHeight)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(.inkInkBase.opacity(0.15)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(book.title), \(Text(book.status.label))"))
        .accessibilityHint("Opens book details")
    }
}
