//
//  NavigationFlowIntegrationTests.swift
//  image-incognitoTests
//
//  Pure state-driven user-flow integration tests.
//  Validates Home -> Editor review -> confirm -> Export without spinning up a
//  UI test runner.
//

import Testing
import UIKit
import SwiftUI
@testable import image_incognito

@Suite("NavigationFlowIntegrationTests", .serialized)
@MainActor
struct NavigationFlowIntegrationTests {

    // MARK: - Mocks

    private struct FlowDetectionRepository: FaceDetectionRepositoryProtocol {
        let faces: [FaceBox]

        func detectFaces(in image: UIImage) async throws -> [FaceBox] {
            faces
        }
    }

    private final class FlowRenderRepository: MaskRenderingRepositoryProtocol {
        private(set) var callCount = 0
        private(set) var lastRegions: [MaskRegion] = []

        func render(
            image: UIImage,
            regions: [MaskRegion],
            solidCleanColor: UIColor
        ) async throws -> UIImage {
            callCount += 1
            lastRegions = regions
            return image
        }
    }

    private func makeSampleImage() -> UIImage {
        let size = CGSize(width: 400, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.systemBlue.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func makeEditorViewModel(
        image: UIImage,
        faces: [FaceBox] = [],
        renderer: FlowRenderRepository? = nil
    ) -> (EditorViewModel, FlowRenderRepository) {
        let renderer = renderer ?? FlowRenderRepository()
        let viewModel = EditorViewModel(
            sourceImage: image,
            detectFacesUseCase: DetectFacesUseCase(
                repository: FlowDetectionRepository(faces: faces)
            ),
            renderMaskUseCase: RenderMaskUseCase(repository: renderer)
        )
        return (viewModel, renderer)
    }

    // MARK: - Tests

    @Test("Review flow: detect, include/exclude, add manual, confirm, Export")
    func reviewFlow() async throws {
        // 1. Home selection
        let homeVM = HomeViewModel()
        #expect(homeVM.selectedImages.isEmpty)
        homeVM.didSelectImages([makeSampleImage()])
        #expect(homeVM.selectedImages.count == 1)

        // 2. Editor detection proposes an included face.
        let face = FaceBox(rect: CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4))
        let (editorVM, renderer) = makeEditorViewModel(
            image: homeVM.selectedImages[0],
            faces: [face]
        )
        await editorVM.detectFaces()

        #expect(editorVM.phase == .reviewing)
        #expect(editorVM.regions.count == 1)
        #expect(editorVM.regions[0].source == .detectedFace)
        #expect(editorVM.includedRegionCount == 1)

        // 3. Exclude, then include again.
        editorVM.toggleInclusion(id: editorVM.regions[0].id)
        #expect(editorVM.includedRegionCount == 0)
        editorVM.toggleInclusion(id: editorVM.regions[0].id)
        #expect(editorVM.includedRegionCount == 1)

        // 4. Add a manual rectangle and apply an emoji style to it.
        editorVM.beginDrawing()
        #expect(editorVM.addManualRegion(
            normalizedRect: CGRect(x: 0.55, y: 0.55, width: 0.25, height: 0.2),
            shape: .rectangle
        ) == .added)
        #expect(editorVM.regions.count == 2)
        #expect(editorVM.includedRegionCount == 2)

        let manualID = try #require(editorVM.selectedRegionID)
        editorVM.applyStyle(.emojiOverlay, to: manualID)
        editorVM.selectedEmoji = "🎭"
        #expect(editorVM.regions[1].style == .emojiOverlay)
        #expect(editorVM.regions[1].selectedEmoji == "🎭")

        // 5. Confirm bakes only included regions.
        let rendered = try await editorVM.confirm(allowEmpty: false)
        #expect(rendered.size == homeVM.selectedImages[0].size)
        #expect(renderer.callCount == 1)
        #expect(renderer.lastRegions.count == 2)
        #expect(editorVM.renderedRevision == editorVM.draftRevision)
        #expect(editorVM.phase == .reviewing)

        // 6. Export receives the rendered images and per-image counts.
        let exportVM = ExportViewModel(
            originalImages: [homeVM.selectedImages[0]],
            maskedImages: [rendered]
        )
        #expect(exportVM.maskedImages.count == 1)
        #expect(exportVM.settings.removeLocation == true)
        #expect(exportVM.settings.removeExif == true)

        // Drafts survive a return from Export (VM-owned state).
        #expect(editorVM.regions.count == 2)
        #expect(editorVM.hasDrafts)
    }

    @Test("Explicit empty override returns the original without rendering")
    func emptyOverrideFlow() async throws {
        let sample = makeSampleImage()
        let (editorVM, renderer) = makeEditorViewModel(image: sample)
        await editorVM.detectFaces()
        #expect(editorVM.regions.isEmpty)

        let result = try await editorVM.confirm(allowEmpty: true)

        #expect(result === sample)
        #expect(renderer.callCount == 0)
    }

    @Test("Multi-image drafts are independent and confirm aggregates counts")
    func multiImageFlow() async throws {
        let imageA = makeSampleImage()
        let imageB = makeSampleImage()

        let (vmA, rendererA) = makeEditorViewModel(
            image: imageA,
            faces: [FaceBox(rect: CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3))]
        )
        let (vmB, rendererB) = makeEditorViewModel(image: imageB)

        await vmA.detectFaces()
        await vmB.detectFaces()

        vmA.toggleInclusion(id: vmA.regions[0].id)
        vmA.toggleInclusion(id: vmA.regions[0].id)
        vmB.beginDrawing()
        #expect(vmB.addManualRegion(
            normalizedRect: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
            shape: .circle
        ) == .added)

        let counts = [vmA.includedRegionCount, vmB.includedRegionCount]
        #expect(counts == [1, 1])

        let renderedA = try await vmA.confirm(allowEmpty: false)
        let renderedB = try await vmB.confirm(allowEmpty: false)

        #expect(renderedA.size == imageA.size)
        #expect(renderedB.size == imageB.size)
        #expect(rendererA.callCount == 1)
        #expect(rendererB.callCount == 1)
    }

    @Test("Settings Flow: Settings Toggle Mutations & Persistence across app sessions")
    func settingsFlowPersistence() {
        let store = SettingsStore()
        store.exportSettings.removeLocation = true
        store.exportSettings.removeExif = true
        store.resetEmojiPresets()

        #expect(store.exportSettings.removeLocation == true)
        #expect(store.emojiPresets.contains("😎"))

        store.addEmojiPreset("🦄")
        #expect(store.emojiPresets.contains("🦄"))

        store.exportSettings.removeLocation = false
        #expect(store.exportSettings.removeLocation == false)

        let newStoreSession = SettingsStore()
        #expect(newStoreSession.exportSettings.removeLocation == false)
        #expect(newStoreSession.emojiPresets.contains("🦄"))
    }
}
