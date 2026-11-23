import SwiftUI
import UIKit

/// Converts the HTML in a Google Books description to an `AttributedString`.
///
/// `NSAttributedString`'s HTML importer must run on the main thread, which matches the
/// project's MainActor default isolation.
enum HTMLText {
    static func attributedString(from html: String) -> AttributedString? {
        guard let data = html.data(using: .utf8) else { return nil }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]
        guard let parsed = try? NSAttributedString(data: data, options: options, documentAttributes: nil),
              var result = try? AttributedString(parsed, including: \.uiKit)
        else { return nil }

        // The importer bakes in Times 12 and black text. Keep only bold/italic as presentation
        // intents so the text uses the surrounding body font, colour and Dynamic Type size.
        for run in result.runs {
            var intent: InlinePresentationIntent = []
            if let traits = run.uiKit.font?.fontDescriptor.symbolicTraits {
                if traits.contains(.traitBold) { intent.insert(.stronglyEmphasized) }
                if traits.contains(.traitItalic) { intent.insert(.emphasized) }
            }
            result[run.range].inlinePresentationIntent = intent.isEmpty ? nil : intent
            result[run.range].uiKit.font = nil
            result[run.range].uiKit.foregroundColor = nil
        }

        let trimmed = String(result.characters).trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : result
    }
}
