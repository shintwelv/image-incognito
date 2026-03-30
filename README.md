# Image Incognito

> Automatically detect faces in photos and apply aesthetic masking to protect privacy — without sacrificing photo quality for SNS sharing.

---

## Overview

**Image Incognito** is an iOS application that uses on-device face detection to instantly find every face in a photo and apply beautiful privacy masks (Blur, Pixelation, and more). Designed for SNS users who care about both portrait rights and aesthetics.

- **No cloud. No account.** All processing runs entirely on-device.
- **Automatic.** No manual cropping or tapping required.
- **Aesthetic-first.** Masks look like creative choices, not censorship patches.

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
│   └── Entities/
│       ├── FaceBox.swift        # Detected face region model
│       ├── MaskingStyle.swift   # Blur, Pixelation, etc.
│       ├── ExportSettings.swift # Export resolution & format config
│       └── RecentMaskingItem.swift
│
├── Data/                    # Framework-dependent implementations
│   └── Services/
│       └── MaskRenderingService.swift  # Core Image / Metal masking
│
├── Presentation/            # SwiftUI Views + ViewModels (MVVM)
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── HomeViewModel.swift
│   ├── Editor/
│   │   ├── EditorView.swift
│   │   └── EditorViewModel.swift
│   ├── Export/
│   │   ├── ExportView.swift
│   │   └── ExportViewModel.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── SettingsStore.swift
│
├── DesignSystem/            # Design tokens, typography, reusable components
│   ├── Tokens.swift
│   ├── Colors.swift
│   ├── Typography.swift
│   └── Components/
│       ├── PrimaryButton.swift
│       ├── CardView.swift
│       └── GlassmorphismToolbar.swift
│
└── Shared/                  # Bridges & utilities
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

Unit tests cover Domain entities and Data layer services:

```
image-incognitoTests/
├── FaceBoxTests.swift
├── MaskingStyleTests.swift
├── ExportSettingsTests.swift
├── RecentMaskingItemTests.swift
├── MaskRenderingServiceTests.swift
├── HomeViewModelTests.swift
├── EditorViewModelTests.swift
├── ExportViewModelTests.swift
└── SettingsStoreTests.swift
```

Run tests in Xcode with `⌘U` or via:

```bash
xcodebuild test \
  -project iOS/image-incognito/image-incognito.xcodeproj \
  -scheme image-incognito \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## Getting Started

1. Clone the repository
2. Open `iOS/image-incognito/image-incognito.xcodeproj` in Xcode
3. Select a simulator or connected device running iOS 17+
4. Press `⌘R` to build and run

No external dependencies — everything uses Apple's native frameworks via Swift Package Manager.

---

## License

See [LICENSE](LICENSE) for details.
