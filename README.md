# Incognify

> AI finds and suggests faces; you review, adjust, and confirm. Manual rectangle, circle, and ellipse masks cover anything else — nothing renders until you confirm.

---

## Overview

**Incognify** is an iOS application that uses on-device face detection to suggest the faces in your photos, then hands control to you. Review the suggestions, include or exclude them, add your own manual masks (Blur, Pixelation, and more), and confirm only when the result looks right. Designed for SNS users who care about both portrait rights and aesthetics.

- **No cloud. No account.** All processing runs entirely on-device.
- **Review-first.** AI suggests faces; you decide what stays visible and what gets masked.
- **Manual anywhere.** Draw a rectangle, circle, or ellipse over plates, tags, documents, or any missed face.
- **Nothing renders until confirm.** Edits stay as suggestions until you approve them.
- **Aesthetic-first.** Masks look like creative choices, not censorship patches.

---

## User flow

1. **Home** — pick photos from the library or camera.
2. **1/2 Review** — check AI face suggestions, include/exclude them, and draw manual rectangle/circle/ellipse regions.
3. **Confirm** — bake the masks. Empty selections or partial photos show a confirmation first.
4. **2/2 Preview & save** — compare with the original, adjust export options, then save or share.

The interface and review flow are localized in English, Korean, Japanese, Spanish, and Simplified Chinese.

---

## Requirements

| Item | Requirement |
|---|---|
| Platform | iOS 17.0+ |
| Xcode | 15.0+ |
| Language | Swift 5.9+ |

---

## Architecture

Clean Architecture with MVVM, organized into three layers:

```
iOS/image-incognito/image-incognito/
├── Domain/                  # Pure business logic — no frameworks
│   ├── Entities/
│   │   ├── ExportSettings.swift
│   │   ├── FaceBox.swift        # Detected face suggestion model
│   │   ├── MaskRegion.swift     # Face/manual region + shape, inclusion, style
│   │   ├── MaskingStyle.swift   # Blur, Pixelation, etc.
│   │   └── RecentMaskingItem.swift
│   ├── Geometry/
│   │   └── RegionGeometry.swift # Normalized rects, translation, resizing
│   ├── Interfaces/
│   │   ├── ExportProcessingRepositoryProtocol.swift
│   │   ├── FaceDetectionRepositoryProtocol.swift
│   │   ├── MaskRenderingRepositoryProtocol.swift
│   │   └── PhotoLibraryRepositoryProtocol.swift
│   └── UseCases/
│       ├── DetectFacesUseCase.swift
│       ├── ProcessExportUseCase.swift
│       ├── RenderMaskUseCase.swift
│       └── SaveToPhotosUseCase.swift
│
├── Data/                    # Framework-dependent implementations
│   ├── Repositories/
│   │   └── SettingsStore.swift
│   └── Services/
│       ├── ExportImageProcessingService.swift
│       ├── FaceDetectionService.swift
│       ├── MaskRenderingService.swift  # Core Image / Metal masking
│       └── PhotoLibraryService.swift
│
├── Presentation/            # SwiftUI Views + ViewModels (MVVM)
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   └── RecentMaskingItem+UIImage.swift
│   ├── Editor/
│   │   ├── AdjustmentSlidersView.swift
│   │   ├── DrawRegionOverlay.swift
│   │   ├── EditorStateViews.swift
│   │   ├── EditorView.swift
│   │   ├── EditorViewModel.swift
│   │   ├── InteractivePopGestureController.swift
│   │   ├── RegionHitTester.swift
│   │   ├── RegionListView.swift
│   │   └── RegionOverlayView.swift
│   ├── Export/
│   │   ├── ExportView.swift
│   │   └── ExportViewModel.swift
│   └── Settings/
│       └── SettingsView.swift
│
├── DesignSystem/            # Design tokens, typography, reusable components
│   ├── Colors.swift
│   ├── Tokens.swift
│   ├── Typography.swift
│   └── Components/
│       ├── CardView.swift
│       ├── GlassmorphismToolbar.swift
│       ├── PrimaryButton.swift
│       ├── Toast.swift
│       └── ToggleCardRow.swift
│
└── Shared/                  # Bridges & utilities
    ├── CameraPickerRepresentable.swift
    ├── IncomingImageStore.swift
    ├── PhotoPickerRepresentable.swift
    └── ShareSheet.swift
```

---

## Core Technologies

| Technology | Purpose |
|---|---|
| **Vision** | On-device face detection |
| **Core Image / Metal** | Hardware-accelerated image masking |
| **PhotosUI** | System photo library access |
| **SwiftUI** | Declarative UI |
| **Swift Concurrency** | `async/await` for background image processing |

---

## Key Conventions

- **State management:** `@Observable` macro (Swift 5.9+)
- **Dependency injection:** Initializer injection throughout
- **Async operations:** `async/await` — image processing always on background threads
- **Reusable UI:** `ViewModifier` for shared styling
- **Error handling:** `throws` propagation

---

## Design System

| Token | Value |
|---|---|
| Primary color | `#5E5CE6` (Indigo) |
| Background | `#F2F2F7` (System Gray 6) |
| Dark background | `#1C1C1E` (Deep Gray) |
| Border radius (card) | `20pt` |
| Border radius (button) | `16pt` |
| Typography | SF Pro (system font), Body 17pt, Title 28pt Bold |

Dark Mode is fully supported across all screens.

---

## Tests

Unit tests cover Domain entities, use cases, ViewModels, geometry helpers, and Data layer services:

```
image-incognitoTests/
├── DetectFacesUseCaseTests.swift
├── EditorViewModelTests.swift
├── ExportImageProcessingServiceTests.swift
├── ExportSettingsTests.swift
├── ExportViewModelTests.swift
├── FaceBoxTests.swift
├── FaceDetectionServiceTests.swift
├── HomeViewModelTests.swift
├── InteractivePopGestureControllerTests.swift
├── LocalizationCoverageTests.swift
├── MaskRegionRenderingTests.swift
├── MaskRegionTests.swift
├── MaskRenderingServiceTests.swift
├── MaskingStyleTests.swift
├── PhotoPickerCoordinatorTests.swift
├── ProcessExportUseCaseTests.swift
├── RecentMaskingItemTests.swift
├── RegionGeometryTests.swift
├── RegionHitTesterTests.swift
├── RenderMaskUseCaseTests.swift
├── SaveToPhotosUseCaseTests.swift
├── SettingsStoreTests.swift
├── TestHelpers.swift
└── image_incognitoTests.swift
```

Run tests in Xcode with `⌘U` or via:

```bash
xcodebuild test \
  -project iOS/image-incognito/image-incognito.xcodeproj \
  -scheme image-incognito \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0'
```

---

## Getting Started

1. Clone the repository
2. Open `iOS/image-incognito/image-incognito.xcodeproj` in Xcode
3. Select a simulator or connected device running iOS 17+
4. Press `⌘R` to build and run

The project has no external package dependencies. Open it in Xcode to build and run it.

---

## License

See [LICENSE](LICENSE) for details.
