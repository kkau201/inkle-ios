# inkle app spec: search, book details, saved library

This spec covers three areas: finding a book, viewing it, and keeping it on your shelf.

## Screens

### Search (Search tab)

A search box ("Title or author") above a list of results.

- **Before searching:** an illustration with "Browse the stacks" and "Look up any book and save it to your shelf."
- **Searching:** starts once typing pauses (0.4 s) or when the keyboard's Search key is pressed. Fewer than 2 characters returns to the idle state. A newer query replaces one still loading.
- **Loading:** a spinner.
- **Results:** one row per book, made up of:
  - a coloured spine (the same colour the book gets on the shelf)
  - the title (up to 2 lines)
  - the authors, comma-separated
  - the published year and the first category, joined by " · "
  
  Tapping a row opens Book details.
- **No matches:** "No results".
- **Error:** an error message with a "Try again" button that repeats the same search.
- The query and its results are kept when you open a book and come back.

### Book details

Opened from a search result or from a book on the shelf.

- **Top bar:**
  - book not saved: **Save**
  - book saved: **Remove** and **Edit**
- **Heading:**
  - the cover image, on the book's spine colour while it loads or when there's no cover
  - the title
  - the authors
  - the published year and page count ("2001 · 320 pages")
- **Tags:** the book's categories, split on "/" with duplicates removed. Three show on one line; a "+N" chip expands to show the rest.
- **On your shelf** card (saved books only):
  - **Status:** Want to read, Reading or Finished, plus the finished date if finished. Tapping it changes the status.
  - **Progress:** a percentage, a bar and "X of Y pages" for books being read or finished. If the page count is unknown, it shows "You're on page X".
  - **Rating:** 1–5 stars, if rated.
  - **Notes:** if any.
- **About:** the book's description, with its HTML formatting.
- **Offline:**
  - If the book can't be loaded but is on the shelf, the screen shows the saved copy with a "Showing your saved copy" notice. The saved copy has no cover, description or tags.
  - The full book loads once the connection returns.
  - If the book isn't saved either, an error dialog is shown.

**Saving.** Save opens "Add to your shelf" with three choices:
- Want to read
- Reading, with an optional "Page you're on"
- Finished, with a finished date (year, optionally month and day)

**Removing.** Remove asks "Remove book?" before deleting the book from the shelf.

### Library (Home tab)

The saved books, drawn as spines on wooden shelves.

- **Header:** "Hello, {name}", the title "Library", the book count ("3 books"), and the user's avatar.
- **Filters:** All, Want to read, Reading, Finished. The heading below them is "Your shelf" for All, or the filter's name.
- **Shelf:**
  - Each book is a coloured spine showing its title. A book's colour and size stay the same each time it's shown.
  - Spines fill each shelf, then continue on the next.
  - With the All filter, the first book being read is pulled out to show a cover face with "READING", the title and its first author.
  - Tapping a book opens Book details.
- **Empty:**
  - no saved books: "Dust settled in" / "Books you save will gather here."
  - nothing matches the filter: "Getting a wee bit dusty in here…"
- The shelf updates when books change, including changes made on another device.

### Edit book

Opened from **Edit** on Book details. It shows the book's title and these fields:
- **Status** chips: Want to read, Reading, Finished
- **Page you're on**, when Reading
- **Finished date** and a 1–5 star **Rating**, when Finished
- **Notes**, free text with a character limit

The screen ends with **Cancel** and **Save** buttons.

## What a saved book keeps

The saved copy keeps these from Google Books:
- the volume ID
- the title
- the authors (up to 10)
- the page count

It adds the user's own data:
- status
- start and finish dates (the finished date can be a year, a month and year, or a full date)
- current page
- rating
- notes

The cover, description, categories and published date aren't saved. Book details fetches them from Google Books each time.

Status follows from the dates: no start date means Want to read, a start date and no finish date means Reading, and both mean Finished. Moving a book back to Want to read clears its current page and rating.

## Google Books API

Base URL: `https://www.googleapis.com/books/v1/`

Every request adds:
- a `key` query parameter (the Books API key)
- `X-Android-Package` and `X-Android-Cert` headers, which must match the key's Android app restriction

| Call | Used by | Request |
|---|---|---|
| Search volumes | Search | `GET volumes?q={query}`. Only `q` is sent: no `maxResults`, `startIndex` or filters, so only the first page of results is shown. |
| Get volume | Book details | `GET volumes/{volumeId}`, where `volumeId` is the `id` from a search result or the ID stored with a saved book. |

### Fields read

Every other field in the response is ignored.

| Field | Shown as |
|---|---|
| `items[]` | Search results. When there are no matches, the API omits this field and the app shows "No results". |
| `id` | Opens Book details. Stored with a saved book to link it back to its volume. |
| `volumeInfo.title` | Title in search rows, details, shelf spines and Edit |
| `volumeInfo.authors[]` | Authors in search rows and details; the first author on the pulled-out shelf book |
| `volumeInfo.description` | The "About" section, with HTML formatting |
| `volumeInfo.imageLinks.thumbnail` | The cover on Book details. Changed from `http://` to `https://`, because the app blocks plain HTTP. |
| `volumeInfo.publishedDate` | The year (first 4 characters if they're digits, otherwise the whole value) in search rows and details |
| `volumeInfo.pageCount` | "N pages" on details and the progress total. `0` is treated as unknown. |
| `volumeInfo.categories[]` | The first category in search rows; tags on details |

### Offline caching

Successful API responses are kept in a 10 MB on-device cache. When online, the app always checks with the API first. When offline, a book that was opened before is shown from the cache.
