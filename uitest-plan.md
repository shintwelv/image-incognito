# UI Test Plan — Incognify (image-incognito)

## Overview

Write XCUITest-based UI tests for the Incognify iOS app. The app detects faces in photos and applies privacy masks. It has 4 screens: **Home**, **Editor**, **Export**, and **Settings**, connected via NavigationStack + sheets.

### Current State

- UI test target exists at `iOS/image-incognito/image-incognitoUITests/` with empty boilerplate (no real tests).
- **Zero accessibility identifiers** exist in the codebase — these must be added to views before tests can locate elements.
- Unit tests (19 files) cover Domain/Data layers well; UI layer has no test coverage.
- VisionKit does **not** work on Simulator — face detection tests must use stubbed/mocked state or test the "no faces found" path.

### Approach

1. **Add accessibility identifiers** to all interactive elements across all 4 screens (prerequisite).
2. **Write UI tests** organized by screen, testing navigation flows, element existence, and user interactions.
3. Use a **launch argument** (e.g. `--uitesting`) to inject test state where needed (skip Firebase, provide stub images).

---

## Phase 1 — Accessibility Identifiers

Add `.accessibilityIdentifier()` to all testable elements. Use dot-notation keys consistent with the localization convention.

### HomeView

| Element | Identifier |
|---------|-----------|
| Settings (gear) button | `home.settingsButton` |
| "Select Photos" button | `home.selectPhotosButton` |
| "Take Photo" button | `home.cameraButton` |
| Hero card | `home.heroCard` |
| Recent section header | `home.recentSectionTitle` |
| "See All" button | `home.recentSeeAllButton` |
| Recent item thumbnail (indexed) | `home.recentItem.\(index)` |
| Image loading overlay | `home.loadingOverlay` |

### EditorView

| Element | Identifier |
|---------|-----------|
| Cancel button | `editor.cancelButton` |
| Confirm button | `editor.confirmButton` |
| Image counter text | `editor.imageCounter` |
| Included region count | `editor.includedCount` |
| Detecting skeleton overlay | `editor.detectingOverlay` |
| No-face-found view | `editor.noFaceFound` |
| Detection-failed view | `editor.detectionFailed` |
| Region overlay (indexed) | `editor.regionOverlay.\(region.id)` |
| Add area button | `editor.addRegion` |
| Drawing overlay | `editor.drawOverlay` |
| Draw cancel button | `editor.drawCancel` |
| Shape picker (per shape) | `editor.shapePicker.rectangle` / `.circle` / `.ellipse` |
| Masking style pill (per style) | `editor.stylePill.\(style.rawValue)` |
| Region list sheet | `editor.regionList` |
| Region row (indexed) | `editor.regionRow.\(region.id)` |
| Region row select (indexed) | `editor.regionRowSelect.\(region.id)` |
| Region row include/exclude (indexed) | `editor.regionRowCheck.\(region.id)` |
| Intensity slider | `editor.intensitySlider` |
| Size multiplier slider | `editor.sizeSlider` |
| Color picker | `editor.colorPicker` |
| Image carousel | `editor.imageCarousel` |
| Page indicator | `editor.pageIndicator` |
| Page dot (indexed) | `editor.pageDot.\(index)` |

### ExportView

| Element | Identifier |
|---------|-----------|
| Back ("Edit areas") button | `export.backButton` |
| Title text | `export.title` |
| Preview image / carousel | `export.previewImage` |
| Masked-areas badge | `export.completionBadge` |
| Compare-with-original hint | `export.compareHint` |
| Dimension label | `export.dimensionLabel` |
| Remove Location toggle | `export.removeLocationToggle` |
| Remove EXIF toggle | `export.removeExifToggle` |
| Keep Resolution toggle | `export.keepResolutionToggle` |
| Save to Album button | `export.saveButton` |
| Share button | `export.shareButton` |
| Save toast | `export.saveToast` |
| Error alert | `export.errorAlert` |

### SettingsView

| Element | Identifier |
|---------|-----------|
| Close button | `settings.closeButton` |
| Navigation title | `settings.title` |
| Remove Location toggle | `settings.removeLocationToggle` |
| Remove EXIF toggle | `settings.removeExifToggle` |
| Keep Resolution toggle | `settings.keepResolutionToggle` |
| Version info row | `settings.versionRow` |
| Developer info row | `settings.developerRow` |

---

## Phase 2 — Test Infrastructure

### File: `UITestHelpers.swift`

- `XCUIApplication` extension with a launch helper that injects `--uitesting` argument.
- Timeout constants for element waits.
- Reusable assertion helpers (e.g., `assertExists`, `assertNotExists`, `waitForElement`).

### File: `AccessibilityIDs.swift` (shared enum)

- Optional: a shared enum or struct mirroring the identifier strings so both app target and test target reference the same constants.

### App-side: `--uitesting` launch argument handling

- In `image_incognitoApp.swift`, check for `ProcessInfo.processInfo.arguments.contains("--uitesting")`.
- When active: skip Firebase init, inject stub images into `IncomingImageStore` to enable Editor testing on Simulator.

---

## Phase 3 — UI Test Cases

### File: `HomeViewUITests.swift`

| # | Test | Description |
|---|------|-------------|
| 1 | `testHomeScreenElementsExist` | Verify hero card, select photos button, camera button, and settings button are visible on launch. |
| 2 | `testSettingsSheetOpens` | Tap gear icon → verify SettingsView appears (check `settings.closeButton` exists). |
| 3 | `testSettingsSheetCloses` | Open settings → tap "Close" → verify settings dismissed. |
| 4 | `testPhotoPickerSheetOpens` | Tap "Select Photos" → verify PHPicker appears (system picker). |
| 5 | `testCameraFullScreenCoverOpens` | Tap "Take Photo" → verify camera UI appears (may fail on Simulator — mark as device-only or skip). |
| 6 | `testRecentSectionHiddenWhenEmpty` | On fresh launch, verify recent section is not visible. |

### File: `EditorViewUITests.swift`

> Requires `--uitesting` stub image injection to navigate to EditorView on Simulator.

| # | Test | Description |
|---|------|-------------|
| 1 | `testEditorElementsExist` | Verify cancel button, confirm button, add-area button, and image carousel are visible. |
| 2 | `testCancelButtonShowsDiscardAlert` | With a draft region, tap cancel → verify the discard confirmation appears; "Keep editing" returns to the editor. |
| 3 | `testDetectingOverlayAppears` | On entry, verify detecting skeleton view appears briefly. |
| 4 | `testNoFaceFoundShown` | With a blank stub image (no faces), verify the no-face view and manual add-area path appear. |
| 5 | `testDetectionSuggestionsIncludeExclude` | On device, verify Vision suggestions appear as `editor.regionOverlay.*`; tap a region or its badge to toggle inclusion and confirm `editor.includedCount` updates. |
| 6 | `testDrawRectangleRegion` | Tap `editor.addRegion` → verify `editor.drawOverlay`; choose `editor.shapePicker.rectangle`, drag on the photo, verify a new manual region overlay. |
| 7 | `testDrawCircleRegion` | Repeat the draw flow with `editor.shapePicker.circle` and verify the circular overlay. |
| 8 | `testDrawEllipseRegion` | Repeat the draw flow with `editor.shapePicker.ellipse` and verify the elliptical overlay. |
| 9 | `testDrawCancel` | Enter drawing mode → tap `editor.drawCancel` → verify no region is added. |
| 10 | `testMaskingStylePillsExist` | Verify all 5 style pills (blurredGlass, pixelArt, crystalize, solidClean, emojiOverlay) are visible. |
| 11 | `testStylePillSelection` | Select a region, tap each style pill → verify selected state changes. |
| 12 | `testRegionListSheet` | Tap the region-list button → verify `editor.regionList`, `editor.regionRow.*`, and close behavior. |
| 13 | `testConfirmDisabledWhileDetecting` | While detection or rendering is in progress, verify the confirm button is disabled. |
| 14 | `testConfirmWithNoRegionsShowsWarning` | Tap confirm with zero included regions → verify `editor.confirmEmpty.title` / export-original choice. |
| 15 | `testMultiImagePageIndicator` | With 2+ stub images, verify `editor.pageIndicator` and `editor.pageDot.*` appear. |

### File: `ExportViewUITests.swift`

> Requires navigation through Editor (use stub images + `--uitesting`).

| # | Test | Description |
|---|------|-------------|
| 1 | `testExportScreenElementsExist` | Verify preview image, masked-areas badge, compare hint, save button, share button, and all 3 toggles are visible. |
| 2 | `testBackButtonReturnsToEditorWithDrafts` | Tap "Edit areas" → verify return to EditorView with drawn regions and selection still intact. |
| 3 | `testToggleDefaultStates` | Verify removeLocation=ON, removeExif=ON, keepResolution=ON by default. |
| 4 | `testToggleInteraction` | Toggle each switch off and on → verify state changes. |
| 5 | `testSaveButtonShowsProgress` | Tap save → verify button text changes to "Saving..." (isSaving state). |
| 6 | `testShareButtonPresentsSheet` | Tap share → verify share sheet appears. |
| 7 | `testMaskedAreasBadgeShowsCorrectCount` | Verify the badge shows the confirmed region count per photo. |
| 8 | `testZeroRegionBadge` | After confirming with the export-original override, verify the badge shows the zero-mask text. |

### File: `SettingsViewUITests.swift`

| # | Test | Description |
|---|------|-------------|
| 1 | `testSettingsElementsExist` | Verify all toggle rows, version row, developer row, and close button are visible. |
| 2 | `testCloseButtonDismisses` | Tap close → verify settings dismissed and HomeView is back. |
| 3 | `testExportSettingsTogglesWork` | Toggle each export setting → verify toggle state changes. |
| 4 | `testVersionInfoDisplayed` | Verify version row shows non-empty version string. |
| 5 | `testSettingsPersistAcrossReopen` | Change a toggle → close settings → reopen → verify toggle state persisted. |

### File: `NavigationFlowUITests.swift`

| # | Test | Description |
|---|------|-------------|
| 1 | `testFullHappyPath` | Home → select stub photo → draw a manual region → confirm → Export screen shows → save → toast appears. |
| 2 | `testHomeToSettingsAndBack` | Home → settings → close → Home. |
| 3 | `testEditorToExportAndBack` | Editor → draw a region → confirm → Export → "Edit areas" → Editor retains the draft regions. |
| 4 | `testDeepNavigationBackToHome` | Home → Editor → draw a region → discard confirmation → leave → Home. |

### File: `image_incognitoUITestsLaunchTests.swift` (update existing)

| # | Test | Description |
|---|------|-------------|
| 1 | `testLaunchPerformance` | Measure app launch time with `measure(metrics: [XCTApplicationLaunchMetric()])`. |
| 2 | `testLaunchScreenshot` | Capture screenshot on launch for visual regression. |

---

## Phase 4 — Localization UI Tests (Optional / Future)

| # | Test | Description |
|---|------|-------------|
| 1 | `testKoreanLocaleStrings` | Launch with `ko` locale → verify key strings appear correctly. |
| 2 | `testEnglishLocaleStrings` | Launch with `en` locale → verify English strings. |
| 3 | `testJapaneseLocaleStrings` | Launch with `ja` locale → verify Japanese strings. |

Use `app.launchArguments += ["-AppleLanguages", "(en)"]` to force locale in tests.

---

## Constraints & Notes

- **Simulator limitation**: Vision face detection is device-only and does not work on Simulator. Editor tests on Simulator must use the no-face/manual path: inject a blank stub image, then exercise `editor.addRegion` and the drawing overlay. Tests that depend on detected face suggestions must run on a device (or inject pre-populated regions with `--uitesting`).
- **Camera**: `UIImagePickerController` camera is unavailable on Simulator. Camera tests should be skipped or marked `XCTSkipIf(true, "Camera not available on Simulator")`.
- **Firebase**: Must be disabled during UI testing to avoid network dependencies and flakiness.
- **Photo Library**: Save-to-album tests will trigger system permission dialogs. Handle with `addUIInterruptionMonitor` or use `--uitesting` to mock the save action.
- **Concurrency**: The app uses Swift 6 strict concurrency (`MainActor` isolation). Test helpers should respect this — no background thread assumptions.

---

## Summary

| Phase | Files to Create/Modify | Scope |
|-------|----------------------|-------|
| 1 | 4 View files + DesignSystem components | Add ~50 accessibility identifiers |
| 2 | 2 new test helpers + App entry point | Test infrastructure & stub injection |
| 3 | 6 test files | ~32 UI test cases |
| 4 | 1 test file (optional) | 3 localization smoke tests |

**Total estimated test cases: ~35** (core) + 3 (localization).
