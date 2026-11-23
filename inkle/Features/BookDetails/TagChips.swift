import SwiftUI
import UIKit

/// Category tags. Collapsed, they sit on one line (at most 3) with a "+N" chip for the rest;
/// tapping "+N" wraps all of them with `FlowLayout`.
struct TagChips: View {
    let tags: [String]

    @State private var expanded = false
    @State private var availableWidth: CGFloat?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let collapsedLimit = 3
    private let spacing: CGFloat = 6
    private let horizontalPadding: CGFloat = 10

    var body: some View {
        Group {
            if expanded {
                FlowLayout(spacing: spacing, lineSpacing: spacing) {
                    ForEach(tags, id: \.self) { chip($0) }
                }
            } else {
                let visible = visibleCount
                HStack(spacing: spacing) {
                    ForEach(tags.prefix(visible), id: \.self) { chip($0) }
                    if visible < tags.count {
                        Button {
                            withAnimation { expanded = true }
                        } label: {
                            chip("+\(tags.count - visible)", tinted: true)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Show \(tags.count - visible) more tags")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { availableWidth = $0 }
    }

    private func chip(_ text: String, tinted: Bool = false) -> some View {
        Text(text)
            .font(.footnote)
            .lineLimit(1)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 5)
            .background(tinted ? AnyShapeStyle(.inkYellow) : AnyShapeStyle(.inkCover),
                        in: Capsule())
            .foregroundStyle(tinted ? AnyShapeStyle(.inkInkBase) : AnyShapeStyle(.inkInk))
    }

    /// How many tags fit on one line next to the "+N" chip, measured with the footnote font so the
    /// collapsed row never wraps.
    private var visibleCount: Int {
        let limit = min(collapsedLimit, tags.count)
        guard let width = availableWidth, width > 0 else { return limit }
        _ = dynamicTypeSize // re-measure when the text size changes
        let font = UIFont.preferredFont(forTextStyle: .footnote)
        func chipWidth(_ text: String) -> CGFloat {
            ceil((text as NSString).size(withAttributes: [.font: font]).width) + horizontalPadding * 2
        }
        for count in stride(from: limit, through: 0, by: -1) {
            var needed = tags.prefix(count).reduce(0) { $0 + chipWidth($1) }
            var items = count
            let hidden = tags.count - count
            if hidden > 0 {
                needed += chipWidth("+\(hidden)")
                items += 1
            }
            needed += spacing * CGFloat(max(items - 1, 0))
            if needed <= width { return count }
        }
        return 0
    }
}

#Preview("Few tags") {
    TagChips(tags: ["Fiction", "Science Fiction"]).padding()
}

#Preview("Many tags") {
    TagChips(tags: ["Fiction", "Science Fiction", "Classics", "Adventure", "Space Opera", "Ecology"])
        .padding()
}
