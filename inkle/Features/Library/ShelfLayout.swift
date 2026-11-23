import SwiftUI

/// Greedy row packing for the shelf: spines fill a row, then continue on the next.
nonisolated enum ShelfLayout {
    /// Splits item widths into rows of indices. A row always holds at least one item.
    static func rows(widths: [CGFloat], available: CGFloat, spacing: CGFloat) -> [[Int]] {
        var rows: [[Int]] = []
        var current: [Int] = []
        var used: CGFloat = 0
        for (index, width) in widths.enumerated() {
            let needed = current.isEmpty ? width : used + spacing + width
            if !current.isEmpty, needed > available {
                rows.append(current)
                current = [index]
                used = width
            } else {
                current.append(index)
                used = needed
            }
        }
        if !current.isEmpty { rows.append(current) }
        return rows
    }
}

/// One thing standing on a shelf.
struct ShelfItem: Identifiable {
    enum Kind { case spine, cover }
    let book: SavedBook
    let kind: Kind

    var id: String { (kind == .cover ? "cover-" : "spine-") + book.volumeID }

    var size: CGSize {
        switch kind {
        case .spine:
            let a = BookAppearance(volumeID: book.volumeID)
            return CGSize(width: a.spineWidth, height: a.spineHeight)
        case .cover:
            return CGSize(width: PulledOutCover.width, height: PulledOutCover.height)
        }
    }
}

/// Rows of items, each standing on a wooden plank.
struct ShelfView: View {
    let items: [ShelfItem]

    private let spacing: CGFloat = 3
    @State private var width: CGFloat = 0

    var body: some View {
        let rows = ShelfLayout.rows(widths: items.map(\.size.width), available: width, spacing: spacing)
        VStack(spacing: 18) {
            ForEach(rows.indices, id: \.self) { r in
                VStack(spacing: 0) {
                    HStack(alignment: .bottom, spacing: spacing) {
                        ForEach(rows[r], id: \.self) { i in
                            let item = items[i]
                            NavigationLink(value: BookRoute(volumeID: item.book.volumeID)) {
                                switch item.kind {
                                case .spine: SpineView(book: item.book)
                                case .cover: PulledOutCover(book: item.book)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 6)
                    Plank()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.width - 12 } action: { width = $0 }
    }
}

/// The shelf plank: a flat #D3C3AB board with a soft top highlight and shadow.
private struct Plank: View {
    var body: some View {
        Rectangle()
            .fill(.inkPlank)
            .overlay(alignment: .top) {
                Rectangle().fill(.inkPaperBase.opacity(0.35)).frame(height: 1)
            }
            .frame(height: 14)
            .shadow(color: .inkInkBase.opacity(0.35), radius: 3, y: 3)
            .accessibilityHidden(true)
    }
}
