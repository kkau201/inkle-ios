import SwiftData
import SwiftUI

@main struct MyApp: App {
    private let client: any BooksClient = GoogleBooksClient()
    @State private var monitor = ConnectivityMonitor()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.booksClient, client)
                .environment(monitor)
        }
        .modelContainer(for: SavedBook.self)
    }
}
