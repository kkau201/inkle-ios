import SwiftData
import SwiftUI

struct BookRoute: Hashable {
    let volumeID: String
}

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                LibraryView()
                    .navigationDestination(for: BookRoute.self) { route in
                        BookDetailsView(volumeID: route.volumeID)
                    }
            }
            .tabItem { Label("Home", systemImage: "house") }

            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
        }
    }
}

#Preview {
    RootTabView()
        .environment(\.booksClient, StubBooksClient())
        .environment(ConnectivityMonitor())
        .modelContainer(for: SavedBook.self, inMemory: true)
}
