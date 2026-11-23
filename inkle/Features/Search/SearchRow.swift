import SwiftUI

struct SearchRow: View {
    let volume: Volume

    var body: some View {
        let info = volume.volumeInfo
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(BookAppearance(volumeID: volume.id).color)
                .frame(width: 6)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(info.title ?? "Untitled").font(.headline).lineLimit(2)
                if let authors = info.authors, !authors.isEmpty {
                    Text(authors.joined(separator: ", ")).font(.subheadline).foregroundStyle(.secondary)
                }
                let meta = [info.year, info.tags.first].compactMap { $0 }.joined(separator: " · ")
                if !meta.isEmpty {
                    Text(meta).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
