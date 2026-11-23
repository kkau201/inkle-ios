import SwiftUI

struct BookRoute: Hashable {
    let volumeID: String
}

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                EmptyStateView(symbol: "books.vertical",
                               title: "Dust settled in",
                               message: "Books you save will gather here.")
                    .navigationTitle("Library")
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
    RootTabView().environment(\.booksClient, StubBooksClient())
}
