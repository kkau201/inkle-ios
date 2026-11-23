# inkle: implementation plan

## Context

`docs/app-spec.md` describes three areas: Search, Book details (plus Save, Remove and Edit) and a Library shelf, all backed by the Google Books API. The repo is still Xcode's template: `inkle/MyApp.swift` and `inkle/ContentView.swift` (Hello world). The project targets iOS/macOS/visionOS 27.2 and has no tests. This plan builds the app in **4 steps, each ending with an app that builds and runs on the iPhone simulator**.

Stack: SwiftUI, **iOS 17.0+**, `@Observable` view models, one `NavigationStack` per tab, `URLSession` with `URLCache`, and SwiftData for the saved library.

Decisions taken (they differ from or fill gaps in the spec):
- **API key:** the spec's `X-Android-Package` / `X-Android-Cert` headers are for an Android-restricted key. iOS uses a **separate iOS-restricted key** and sends `X-Ios-Bundle-Identifier: <bundle id>`. The key is kept in an untracked `Secrets.xcconfig`.
- **Platforms:** iOS/iPadOS only (`SUPPORTED_PLATFORMS = iphoneos iphonesimulator`, `TARGETED_DEVICE_FAMILY = 1,2`, `IPHONEOS_DEPLOYMENT_TARGET = 17.0`). No `#if os` guards are needed.
- **iCloud sync:** out of scope for now. The model is still **CloudKit-compatible** (every property optional or defaulted, no `@Attribute(.unique)`, no required relationships), so sync can later be switched on with `ModelConfiguration(cloudKitDatabase: .private("iCloud.…"))` plus the iCloud and Background Modes → Remote notifications capabilities.
- **"Hello, {name}" and avatar:** placeholder `UserProfile` (a hardcoded name and an initials avatar).
- **Notes character limit:** 1,000 characters. The spec doesn't give a number; change it if needed.

API facts were checked against Context7 (`/websites/developer_apple_swiftui`, `/websites/developer_apple_swiftdata`):
- Put `navigationDestination(for:)` **outside** lazy containers (`List`, `LazyVStack`).
- Use `onSubmit(of: .search)` for the keyboard's Search key.
- `@Query(filter:sort:)` can be re-initialised in a view's `init`.
- CloudKit can't enforce `.unique` and needs optional relationships.

## Architecture

```
inkle/
  App/          MyApp.swift (modelContainer, injects BooksClient), RootTabView.swift, UserProfile.swift
  Networking/   BooksClient.swift (protocol + GoogleBooksClient), BooksDTO.swift, APIConfig.swift
  Model/        SavedBook.swift (@Model), ReadingStatus.swift, PartialDate.swift, BookAppearance.swift
  Features/
    Search/       SearchViewModel.swift, SearchView.swift, SearchRow.swift
    BookDetails/  BookDetailsViewModel.swift, BookDetailsView.swift, TagChips.swift, ShelfCard.swift, AddToShelfSheet.swift, HTMLText.swift
    Library/      LibraryView.swift, ShelfLayout.swift, SpineView.swift, PulledOutCover.swift
    EditBook/     EditBookView.swift
  Shared/       ConnectivityMonitor.swift, FlowLayout.swift, EmptyStateView.swift, PreviewData.swift
```

`Use the Xcode MCP tools (`XcodeWrite`, `UpdateTargetBuildSetting`, `AddInfoPlist`, `BuildProject`, `RunProject`, `RenderPreview`).

Key cross-cutting pieces:
- **`BooksClient` protocol:** `search(_ query: String) async throws -> [Volume]` and `volume(id:) async throws -> Volume`. It's injected through `@Environment` so previews can use a stub.
- **`GoogleBooksClient`:**
  - Uses its own `URLSession` with `URLCache(memoryCapacity: 2 MB, diskCapacity: 10 MB)` and the default `.useProtocolCachePolicy`, so online requests always check with the API first.
  - When a request fails with `URLError.notConnectedToInternet`, `.networkConnectionLost` or `.timedOut`, it retries once with `.returnCacheDataDontLoad`. That gives the offline "a book opened before is shown from the cache" behaviour.
  - Adds the `key` query item and the `X-Ios-Bundle-Identifier` header.
- **DTOs:** `VolumesResponse { items: [Volume]? }` and `Volume { id, volumeInfo }`. `VolumeInfo` has only the fields the spec reads, all optional, `imageLinks.thumbnail` included. Computed helpers:
  - `year`: first 4 characters if they're digits, otherwise the whole value
  - `coverURL`: `http://` → `https://`
  - `knownPageCount`: `0` → nil
  - `tags`: each category split on "/", trimmed, duplicates removed in order
- **`BookAppearance`:** a stable colour, spine width and spine height derived from the volume ID with an **FNV-1a hash**. Not `hashValue`, which is seeded per launch. Search rows, the details heading and the shelf all use it, so a book always looks the same.
- **`SavedBook` (@Model):**
  - From Google Books: `volumeID = ""`, `title = ""`, `authors: [String] = []` (capped at 10), `pageCount: Int?`
  - User data: `startDate: Date?`, `finishedYear/Month/Day: Int?` (the `PartialDate`), `currentPage: Int?`, `rating: Int?`, `notes: String?`, `savedAt = Date.now`
  - `status` is computed: no start → Want to read; start and no finish → Reading; both → Finished
  - `setStatus(_:)`:
    - Want to read clears the start date, finish date, page and rating.
    - Reading sets the start date if missing and clears the finish date.
    - Finished sets the start date if missing and sets the finish date.
  - A volume ID is saved only once: code fetches by `volumeID` before inserting.
- **Navigation:** `RootTabView` has a Home (Library) tab and a Search tab, each with its own `NavigationStack`. Both register `.navigationDestination(for: BookRoute.self) { BookDetailsView(volumeID:) }` on the stack root, outside any `List`. `BookRoute { volumeID: String }`. Rows use `NavigationLink(value:)`.

---

## Step 1: Project setup, networking and Search (done)

**Goal:** the app launches into tabs, and Search works end to end against Google Books.

1. **Build settings** (`UpdateTargetBuildSetting`):
   - iOS-only platforms and device family 1,2, deployment target 17.0
   - a real `PRODUCT_BUNDLE_IDENTIFIER` (e.g. `com.<you>.inkle`), which the API key restriction must match
2. **Secrets:**
   - `Secrets.xcconfig` (in `.gitignore`) sets `GOOGLE_BOOKS_API_KEY`, and a committed `Secrets.example.xcconfig` shows the format. Set it as the target's base configuration.
   - `AddInfoPlist`: `GoogleBooksAPIKey = $(GOOGLE_BOOKS_API_KEY)`. `APIConfig` reads it with `Bundle.main.object(forInfoDictionaryKey:)` and the bundle ID.
   - If the key is empty, send requests without `key` (keyless quota) so the app still runs.
3. **Networking:** `BooksDTO.swift`, `BooksClient.swift` and `APIConfig.swift` as described above. Mark the decoding helpers `nonisolated` (the project defaults to MainActor isolation).
4. **`SearchViewModel` (@Observable):**
   - `query: String` and `state: .idle | .loading | .results([Volume]) | .empty | .failed(String)`
   - `queryChanged()` cancels the stored `searchTask` and starts a new one that sleeps 0.4 s and then searches. `submit()` searches immediately. `retry()` repeats the last query.
   - A query shorter than 2 characters (trimmed) → `.idle`.
   - The view model owns the debounce `Task` instead of using `.task(id:)`. A view-scoped task would be cancelled when Book details is pushed and would search again on return, which breaks "query and results are kept".
5. **`SearchView`:**
   - The VM is held in `@State` at the tab root, so it survives pushes.
   - `.searchable(text: $vm.query, prompt: "Title or author")`, `.onChange(of: vm.query) { vm.queryChanged() }`, `.onSubmit(of: .search) { vm.submit() }`
   - States:
     - idle: an illustration (SF Symbol `books.vertical`) with "Browse the stacks" / "Look up any book and save it to your shelf."
     - loading: `ProgressView`
     - empty: "No results"
     - failed: the message and a "Try again" button
6. **`SearchRow`:** the spine colour bar, the title (`lineLimit(2)`), comma-joined authors, and `[year, firstCategory].compacted().joined(" · ")`.
7. **`RootTabView`:** the Home tab shows an `EmptyStateView` ("Dust settled in" / "Books you save will gather here."). `BookRoute` pushes a temporary `BookDetailsView` stub that shows the volume ID.
8. Remove `ContentView.swift`, or turn it into `RootTabView`.

**Done when:**
- `BuildProject` succeeds, and `RunProject` on an iPhone simulator shows both tabs.
- Typing "dune" shows results after a pause. Results come back after pushing and popping a row.
- Airplane mode (Network Link Conditioner, or turning off the Mac's network) shows the error and "Try again".
- `RenderPreview` works for `SearchView` with a stub client for each state.

## Step 2: Book details from the API (read-only) (done)

**Goal:** tapping a search result shows the full details screen. Nothing is saved yet.

1. **`BookDetailsViewModel` (@Observable):**
   - Takes `volumeID` and the client. `phase: .loading | .loaded(Volume) | .failed`.
   - `load()` runs from `.task`.
2. **`BookDetailsView` heading:**
   - `AsyncImage(url: coverURL)` on a `BookAppearance` colour background. The background shows while loading, on failure, and when there's no URL.
   - Then the title, the authors, and `[year, "\(n) pages"]` joined by " · ".
3. **`TagChips`:**
   - Built on `FlowLayout` (a custom `Layout`). Collapsed, it shows the first 3 tags on one line plus a "+N" chip; tapping "+N" expands to all tags.
   - Measure the chips so the collapsed row never wraps. If 3 don't fit, show as many as fit and fold the rest into "+N".
4. **`HTMLText`:**
   - Converts the description with `NSAttributedString(data:options:[.documentType: .html, .characterEncoding: utf8])` → `AttributedString`, with the font and colour normalised to body style. That API must run on the main thread, which matches the project's MainActor default.
   - The conversion runs once in the VM, not in `body`.
   - Shown in an "About" section.
5. **Error:** if the load fails, show an `.alert` and pop on dismiss. (Step 3 adds the saved-copy fallback.)
6. The top bar is an empty placeholder until step 3.

**Done when:**
- Build and run succeed. Opening several books shows the cover or colour fallback, the year · pages, tags with "+N", and the formatted About text.
- Opening a book, going offline and opening it again shows it from the 10 MB cache.
- Opening a never-seen book offline shows the error dialog.
- Previews render with stub volumes: one with a cover and one without, one with many categories and one with none.

## Step 3: SwiftData library: Save, Remove, shelf card, offline fallback, Library list (done)

**Goal:** books can be saved and removed, and they show up on the Home tab.

1. **Model:** `SavedBook`, `ReadingStatus` and `PartialDate` as described above. `MyApp` gets `.modelContainer(for: SavedBook.self)`, local only.
2. **`BookDetailsView` + SwiftData:**
   - `@Query(filter: #Predicate<SavedBook> { $0.volumeID == id })` is built in `init`, so the screen reacts to saves and deletes.
   - Top bar:
     - not saved: **Save**
     - saved: **Remove** and **Edit** (Edit is disabled until step 4)
3. **`AddToShelfSheet` ("Add to your shelf"):**
   - Three options: Want to read; Reading, with an optional "Page you're on" field (numbers only, clamped to the page count when known); Finished, with a `PartialDate` picker (year required, month and day optional).
   - On confirm, insert a `SavedBook` built from the loaded `Volume`, with authors capped at 10 and `pageCount` 0 → nil.
4. **Remove:** `.confirmationDialog("Remove book?")` → `modelContext.delete`.
5. **`ShelfCard` ("On your shelf"):**
   - Status row: the label, plus the finished date when Finished. Tapping it opens a `Menu` of the three statuses → `setStatus`.
   - Progress for Reading and Finished: percentage, `ProgressView(value:)` and "X of Y pages". Without a page count, it shows "You're on page X".
   - Stars if rated, and notes if present.
6. **Offline fallback:**
   - `ConnectivityMonitor` (@Observable, wraps `NWPathMonitor`) is injected through the environment.
   - If the load fails and a `SavedBook` exists, render from it with a "Showing your saved copy" banner. The saved copy has no cover, description or tags.
   - When `isConnected` turns true, reload with `.onChange(of: monitor.isConnected)`.
   - If the load fails and the book isn't saved, show the error alert from step 2.
7. **Library tab (functional version):**
   - Header: "Hello, {UserProfile.name}", the title "Library", a book count with plural handling via the String Catalog ("1 book" / "3 books"), and an initials avatar.
   - Filter chips: All, Want to read, Reading, Finished. The heading is "Your shelf" or the filter name.
   - `@Query(sort: \SavedBook.savedAt)` loads all books, and the view filters by computed `status` in memory. Status is derived, so it can't go into a `#Predicate`, and a shelf is small.
   - Temporary layout: a simple `LazyVGrid` of coloured spine tiles that push `BookRoute`.
   - Empty states:
     - no books: "Dust settled in" / "Books you save will gather here."
     - nothing matches the filter: "Getting a wee bit dusty in here…"

**Done when:**
- Build and run succeed.
- Save a book as each status. Each appears in Library under the right filter, and the count updates.
- Changing status from the card updates the filters live. Moving a book back to Want to read clears its page and rating.
- Remove asks first, then the book disappears.
- Data survives relaunch.
- Offline, a saved book that was never cached shows the saved-copy banner and loads fully once the network is back.

## Step 4: Wooden shelf, Edit book, polish (done)

**Goal:** the app matches the spec.

1. **`ShelfLayout`** (a custom `Layout`, or rows computed from the `GeometryReader` width):
   - Greedily packs spines, each with a fixed width and height from `BookAppearance`, into rows that fill the available width, then continues on the next row.
   - Each row sits on a wooden plank: a gradient and shadow `Rectangle` with a subtle grain made from a few overlaid gradients. No image assets needed.
2. **`SpineView`:** the colour fill and a vertical title (rotated `Text`, `lineLimit(2)`, `minimumScaleFactor`). Tapping it pushes `BookRoute`.
3. **`PulledOutCover`:**
   - Only with the All filter: the first book with status `.reading` (by `savedAt`) is placed first and drawn wider as a cover face.
   - It shows the spine colour, "READING", the title and the first author.
4. **`EditBookView`** (sheet from **Edit**):
   - Shows the book's title.
   - Status chips. "Page you're on" when Reading. A `PartialDate` picker and 1–5 star rating when Finished. A Notes `TextEditor` with a live counter and the 1,000-character limit enforced.
   - Edits go to a local draft struct. **Cancel** discards it. **Save** applies it with `setStatus` + field writes, so the Want to read clearing rule always applies.
5. **Polish:**
   - VoiceOver labels on spines, chips and stars.
   - Dynamic Type checks on the details screen and the rows.
   - A `PreviewData` in-memory `ModelContainer` with sample books for `LibraryView` and `EditBookView` previews.
   - Replace the step 1 `BookDetailsView` stub leftovers, if any.

**Done when:**
- Build and run succeed.
- With books in every status, spines fill the rows and wrap, and they keep the same colour and size across relaunches.
- Under All, the first Reading book is pulled out.
- Edit changes the status, page, date, rating and notes, Cancel leaves the book unchanged, and the notes limit holds.
- `RenderPreview` works for `LibraryView`, `EditBookView` and `BookDetailsView` (saved and unsaved).

## Verification (every step)

1. `BuildProject`: no errors. Fix warnings related to concurrency isolation.
2. `XcodeListRunDestinations` → pick an iPhone 17-or-later simulator → `RunProject`, then walk through that step's "Done when" list.
3. `RenderPreview` for each new view with stub or in-memory data.
4. Pure logic can be checked quickly with `RunCodeSnippet` or a `#Playground`: year parsing, tag splitting, FNV appearance stability, `setStatus` rules, and `PartialDate` formatting. There's no test target. Adding a unit-test target for these is a cheap follow-up.

## Later (not in these 4 steps)

- iCloud sync: add the iCloud + CloudKit container and Background Modes → Remote notifications, and set `ModelConfiguration(cloudKitDatabase: .private(...))`. The model already complies.
- A real user profile (name and avatar).
- Unit-test target.
