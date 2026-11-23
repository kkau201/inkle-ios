# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

A minimal SwiftUI multiplatform app (single target `MyApp`) created from Xcode's "Untitled Project" template. Entry point is `MyApp/MyApp.swift` (`@main` App with a `WindowGroup` hosting `ContentView`). `ContentView.swift` also contains a `#Preview` and a `#Playground` block (from the `Playgrounds` framework) for quick experiments.

There is currently no test target, no README, and no git repository.

## Building and running

Work through the Xcode MCP tools (`xcode-tools`) rather than the command line:

- Build: `BuildProject`
- Run: `RunProject` / `StopProject`; pick destinations with `XcodeListRunDestinations` + `XcodeSwitchRunDestination`
- Fast diagnostics for a single file: `XcodeRefreshCodeIssuesInFile`
- Previews: `RenderPreview`; scratch code: `RunCodeSnippet`

## Project file format

The project uses the JSON-style `Untitled Project.xcodeproj/project.xcproj` (not a `project.pbxproj`). The `MyApp` folder is added as a synchronized folder reference with target membership in `MyApp`, so new files placed in `MyApp/` are picked up automatically — no project file edits needed. Prefer Xcode MCP tools (`XcodeWrite`, `XcodeMV`, `XcodeRM`, `UpdateTargetBuildSetting`, `AddEntitlement`, `AddInfoPlist`) over hand-editing the project file.

## Build settings that affect code

- `SUPPORTED_PLATFORMS`: iOS, iPadOS, macOS, and visionOS (`TARGETED_DEVICE_FAMILY` 1,2,7) — code must compile for all of them; guard platform-specific APIs with `#if os(...)`.
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES`: types and functions are main-actor isolated by default; mark background work explicitly (e.g. `nonisolated`, `@concurrent`).
- `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`: each file must explicitly import the modules whose members it uses.
- `SWIFT_VERSION = 5.0` (Swift 5 language mode).
- App Sandbox enabled with read-only user-selected file access; Info.plist is generated (`GENERATE_INFOPLIST_FILE`), so add keys via `INFOPLIST_KEY_*` build settings or `AddInfoPlist`.
- `STRING_CATALOG_GENERATE_SYMBOLS` / `SWIFT_EMIT_LOC_STRINGS` are on; development language is `en`.
