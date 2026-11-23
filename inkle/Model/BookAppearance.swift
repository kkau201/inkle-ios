import SwiftUI

/// Stable look for a book, derived from its volume ID with FNV-1a (not `hashValue`, which is seeded per launch).
struct BookAppearance {
    let color: Color
    let spineWidth: CGFloat
    let spineHeight: CGFloat

    init(volumeID: String) {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in volumeID.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        let hue = Double(hash % 360) / 360
        let saturation = 0.35 + Double((hash >> 8) % 30) / 100
        let brightness = 0.55 + Double((hash >> 16) % 25) / 100
        color = Color(hue: hue, saturation: saturation, brightness: brightness)
        spineWidth = CGFloat(28 + (hash >> 24) % 20)
        spineHeight = CGFloat(120 + (hash >> 32) % 50)
    }
}
