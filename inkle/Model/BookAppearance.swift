import SwiftUI

/// Stable look for a book, derived from its volume ID with FNV-1a (not `hashValue`, which is seeded per launch).
struct BookAppearance {
    let color: Color
    let spineWidth: CGFloat
    let spineHeight: CGFloat

    /// The fixed brand palette (same in light and dark), like Android's `allColors`.
    static let palette: [Color] = [.inkOrange, .inkPurple, .inkGreen, .inkBlue, .inkYellow]

    init(volumeID: String) {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in volumeID.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        color = Self.palette[Int(hash % UInt64(Self.palette.count))]
        spineWidth = CGFloat(28 + (hash >> 24) % 20)
        spineHeight = CGFloat(120 + (hash >> 32) % 50)
    }
}
