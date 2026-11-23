import SwiftUI

@main struct MyApp: App {
    private let client: any BooksClient = GoogleBooksClient()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.booksClient, client)
        }
    }
}
