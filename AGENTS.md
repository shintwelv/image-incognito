# Agent Rules

iOS app (Incognify) — detects faces in photos and applies privacy masks. iOS 17+, SwiftUI, Clean Architecture (Domain / Data / Presentation), MVVM.

## Coding Conventions
- Async/Await, `@Observable`, `ViewModifier`, Initializer Injection, `throws`.
- Swift 6 strict concurrency (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`):
  - Background-safe methods: `nonisolated`. Non-`Sendable` stored properties safe post-init: `nonisolated(unsafe)`.
  - Wrap non-`Sendable` ObjC types in `@unchecked Sendable` when crossing actor boundaries.
  - `TaskGroup` / `withCheckedContinuation` over `DispatchGroup`.
  - Domain entities + use cases: `nonisolated` + `Sendable`. Repository protocols: `: Sendable`.

## Localization
- Languages: `en`, `ko`, `ja`, `es`, `zh-Hans`.
- Use `String(localized:)` / `LocalizedStringKey`. Store in `Localizable.xcstrings` (String Catalog). No legacy `.strings` files.
- Dot-notation keys with context prefix, e.g. `editor.noFaceFound.title`.
- All 5 translations required when adding/editing a string.

## Domain Terms
- **Mask**: an applied filter instance on a detected face.
- **Obfuscation**: the act of applying that filter.

## Design Tokens
| Category | Value |
| :--- | :--- |
| Primary color | `#5E5CE6` (Indigo) |
| Background | `#F2F2F7` / Dark: `#1C1C1E` |
| Border radius | Elements 12pt · Buttons 16pt · Cards 20pt |
| Typography | SF, Body 17pt, Title 28pt Bold |

## Constraints
- VisionKit does not work on Simulator — use device for face detection testing.
- Image processing must run on background threads.
- After fixing a bug or implementing a feature, add or update the relevant test code.
- Unit-test Domain logic and Data layer pipelines.
