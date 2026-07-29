//
//  NavigationFlowIntegrationTests.swift
//  image-incognitoTests
//
//  Pure State-Driven User Flow Integration Tests.
//  Validates end-to-end user navigation flows from Home -> Editor -> Export -> Settings
//  instantly without spinning up heavy XCTest UI runner processes.
//

import Testing
import UIKit
import SwiftUI
@testable import image_incognito

@Suite("NavigationFlowIntegrationTests", .serialized)
@MainActor
struct NavigationFlowIntegrationTests {

    private func makeSampleImage() -> UIImage {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.systemBlue.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    @Test("Full Happy Path: Home -> Photo Selection -> Editor -> Masking -> Export")
    func fullHappyPathFlow() async throws {
        // 1. Home ViewModel initialized
        let homeVM = HomeViewModel()
        #expect(homeVM.selectedImages.isEmpty)
        #expect(homeVM.isShowingPhotoPicker == false)

        // 2. User selects photo from photo picker
        let sampleImage = makeSampleImage()
        homeVM.didSelectImages([sampleImage])

        #expect(homeVM.selectedImages.count == 1)

        // 3. Editor ViewModel created with selected image
        let editorVM = EditorViewModel(sourceImage: homeVM.selectedImages[0])
        #expect(editorVM.selectedStyle == .blurredGlass)

        // Simulate face detection
        let faceBox = FaceBox(
            rect: CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4),
            isMasked: true,
            style: .blurredGlass
        )
        editorVM.faces = [faceBox]
        editorVM.selectedFaceID = faceBox.id

        // User changes masking style to Emoji Overlay and picks an emoji
        editorVM.selectStyle(.emojiOverlay)
        #expect(editorVM.selectedStyle == .emojiOverlay)
        #expect(editorVM.faces[0].style == .emojiOverlay)

        editorVM.setEmojiForSelectedFace("🎭")
        #expect(editorVM.faces[0].selectedEmoji == "🎭")

        // 4. Export Tapped: Renders masked image
        await editorVM.exportTapped()
        let renderedImage = try #require(editorVM.renderedImage)
        #expect(renderedImage.size == sampleImage.size)

        // 5. Export ViewModel initialized
        let exportVM = ExportViewModel(
            originalImages: [sampleImage],
            maskedImages: [renderedImage]
        )
        #expect(exportVM.maskedImages.count == 1)
        #expect(exportVM.settings.removeLocation == true)
        #expect(exportVM.settings.removeExif == true)

        // User toggles export settings
        exportVM.settings.removeLocation = false
        #expect(exportVM.settings.removeLocation == false)

        // User triggers share action
        exportVM.shareImageTapped()
        #expect(exportVM.settings.removeLocation == false)
    }

    @Test("Settings Flow: Settings Toggle Mutations & Persistence across app sessions")
    func settingsFlowPersistence() {
        let store = SettingsStore()
        store.exportSettings.removeLocation = true
        store.exportSettings.removeExif = true
        store.resetEmojiPresets()

        #expect(store.exportSettings.removeLocation == true)
        #expect(store.emojiPresets.contains("😎"))

        // Add custom emoji preset
        store.addEmojiPreset("🦄")
        #expect(store.emojiPresets.contains("🦄"))

        // Mutate settings
        store.exportSettings.removeLocation = false
        #expect(store.exportSettings.removeLocation == false)

        // New session restores settings & presets
        let newStoreSession = SettingsStore()
        #expect(newStoreSession.exportSettings.removeLocation == false)
        #expect(newStoreSession.emojiPresets.contains("🦄"))
    }
}
