# CLAUDE.md

## Project overview

inkle is a SwiftUI app (single target `inkle`) for searching books on the Google Books API and keeping a personal library shelf. The code is still Xcode's template: `inkle/MyApp.swift` (`@main struct MyApp`, a `WindowGroup` hosting `ContentView`) and `inkle/ContentView.swift` (Hello world plus a `#Preview` and a `#Playground` block from the `Playgrounds` framework).

There is no test target and no README.

## Product docs

- `docs/app-spec.md` describes what the app does: Search, Book details (Save / Remove / Edit), the Library shelf, the saved-book data model, and the Google Books API calls and fields used.
- `docs/plan.md` is the agreed implementation plan: 4 steps, each ending in an app that builds and runs, plus the target architecture (`inkle/App`, `Networking`, `Model`, `Features/…`, `Shared`; a `BooksClient` protocol injected via `@Environment`; SwiftData `SavedBook`; a stable FNV-1a `BookAppearance`). Read it before implementing anything.
- Where the plan disagrees with the spec or the current project, the plan wins. In particular: iOS/iPadOS only with a 17.0 deployment target, an iOS-restricted API key kept in an untracked `Secrets.xcconfig`, and the `X-Ios-Bundle-Identifier` header instead of the spec's Android headers.
- `inkle.xcodeproj/docs/app-spec.md` is a stray duplicate. `docs/` holds the canonical copy.

## Building and running

Work through the Xcode MCP tools (`xcode-tools`) rather than the command line:

- Build: `BuildProject`
- Run: `RunProject` / `StopProject`; pick destinations with `XcodeListRunDestinations` + `XcodeSwitchRunDestination`
- Fast diagnostics for a single file: `XcodeRefreshCodeIssuesInFile`
- Previews: `RenderPreview`; scratch code: `RunCodeSnippet`

With no test target, check pure logic with `RunCodeSnippet` or a `#Playground` block.

## Project file format

The project uses the JSON-style `inkle.xcodeproj/project.xcproj` (not a `project.pbxproj`). The `inkle/` folder is a synchronized folder reference with membership in target `inkle`, so new files placed anywhere under `inkle/` are picked up automatically, with no project file edits needed. Prefer Xcode MCP tools (`XcodeWrite`, `XcodeMV`, `XcodeRM`, `UpdateTargetBuildSetting`, `AddEntitlement`, `AddInfoPlist`) over hand-editing the project file.

## Build settings that affect code

- Platforms: the project currently targets iOS, iPadOS, macOS and visionOS (`TARGETED_DEVICE_FAMILY` 1,2,7). Step 1 of `docs/plan.md` narrows this to iOS/iPadOS 17.0. Check `SUPPORTED_PLATFORMS` in the project file before deciding whether `#if os(...)` guards are needed.
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES`: types and functions are main-actor isolated by default; mark background work explicitly (e.g. `nonisolated`, `@concurrent`).
- `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`: each file must explicitly import the modules whose members it uses.
- `SWIFT_VERSION = 5.0` (Swift 5 language mode).
- App Sandbox enabled with read-only user-selected file access; Info.plist is generated (`GENERATE_INFOPLIST_FILE`), so add keys via `INFOPLIST_KEY_*` build settings or `AddInfoPlist`.
- `STRING_CATALOG_GENERATE_SYMBOLS` / `SWIFT_EMIT_LOC_STRINGS` are on; development language is `en`.
