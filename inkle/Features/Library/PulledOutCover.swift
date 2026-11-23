import SwiftUI

/// The book being read, pulled out to show its cover face.
struct PulledOutCover: View {
    static let width: CGFloat = 120
    static let height: CGFloat = 180

    let book: SavedBook

    var body: some View {
        ZStack(alignment: .topLeading) {
            BookAppearance(volumeID: book.volumeID).color
            VStack(alignment: .leading, spacing: 6) {
                Text("READING")
                    .font(.caption2.bold())
                    .tracking(1.5)
                    .foregroundStyle(.inkInkBase.opacity(0.6))
                Text(book.title)
                    .font(.subheadline.bold())
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 0)
                if let author = book.authors.first {
                    Text(author).font(.caption).lineLimit(2)
                }
            }
            .foregroundStyle(.inkInkBase)
            .padding(10)
        }
        .frame(width: Self.width, height: Self.height)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .inkInkBase.opacity(0.3), radius: 4, x: 2, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Currently reading: \(book.title)"))
        .accessibilityHint("Opens book details")
    }
}
