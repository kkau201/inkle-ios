import SwiftUI

/// Temporary stub; replaced in step 2.
struct BookDetailsView: View {
    let volumeID: String

    var body: some View {
        Text(volumeID)
            .navigationTitle("Book")
            .navigationBarTitleDisplayMode(.inline)
    }
}
