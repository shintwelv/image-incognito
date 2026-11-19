//
//  EditorViewModelTests.swift
//  image-incognitoTests
//
//  Unit tests for the review-state EditorViewModel: detection proposals,
//  inclusion, manual regions, direct manipulation, styles, and the explicit
//  confirm/render contract (including no silent fallback).
//

import Testing
import SwiftUI
import UIKit
@testable import image_incognito

@MainActor
@Suite("EditorViewModel")
struct EditorViewModelTests {

    // MARK: - Mocks

    private struct StubDetectionRepository: FaceDetectionRepositoryProtocol {
        let faces: [FaceBox]
        let error: Error?

        init(faces: [FaceBox] = [], error: Error? = nil) {
            self.faces = faces
            self.error = error
        }

        func detectFaces(in image: UIImage) async throws -> [FaceBox] {
            if let error { throw error }
            return faces
        }
    }

    private final class RenderSpy: MaskRenderingRepositoryProtocol {
        private(set) var callCount = 0
        private(set) var capturedRegions: [MaskRegion] = []
        private(set) var capturedColor: UIColor?
        let result: UIImage
        let error: Error?

        init(result: UIImage = makeTestImage(), error: Error? = nil) {
            self.result = result
            self.error = error
        }

        func render(
            image: UIImage,
            regions: [MaskRegion],
            solidCleanColor: UIColor
        ) async throws -> UIImage {
            callCount += 1
            capturedRegions = regions
            capturedColor = solidCleanColor
            if let error { throw error }
            return result
        }
    }

    private struct RenderFailure: Error {}

    // MARK: - Helpers

    private func makeFace(
        x: CGFloat = 0.1,
        y: CGFloat = 0.1,
        width: CGFloat = 0.3,
        height: CGFloat = 0.3
    ) -> FaceBox {
        FaceBox(rect: CGRect(x: x, y: y, width: width, height: height))
    }

    private func makeViewModel(
        image: UIImage = makeTestImage(),
        faces: [FaceBox] = [],
        detectionError: Error? = nil,
        renderError: Error? = nil,
        renderResult: UIImage? = nil
    ) -> (EditorViewModel, RenderSpy) {
        let detection = DetectFacesUseCase(
            repository: StubDetectionRepository(faces: faces, error: detectionError)
        )
        let spy = RenderSpy(result: renderResult ?? makeTestImage(), error: renderError)
        let viewModel = EditorViewModel(
            sourceImage: image,
            detectFacesUseCase: detection,
            renderMaskUseCase: RenderMaskUseCase(repository: spy)
        )
        return (viewModel, spy)
    }

    /// Creates a VM that has finished detection with no faces.
    private func makeReviewedViewModel(
        renderError: Error? = nil
    ) -> (EditorViewModel, RenderSpy) {
        let (viewModel, spy) = makeViewModel(renderError: renderError)
        viewModel.phase = .reviewing
        return (viewModel, spy)
    }

    private func addManual(
        _ viewModel: EditorViewModel,
        rect: CGRect = CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.3),
        shape: MaskRegion.Shape = .rectangle
    ) {
        viewModel.phase = .reviewing
        let result = viewModel.addManualRegion(normalizedRect: rect, shape: shape)
        #expect(result == .added)
    }

    // MARK: - Initial state

    @Test("Initial state is analyzing with no regions")
    func initialState() {
        let vm = EditorViewModel(sourceImage: makeTestImage())

        #expect(vm.regions.isEmpty)
        #expect(vm.selectedRegionID == nil)
        #expect(vm.phase == .analyzing)
        #expect(vm.isDetecting)
        #expect(vm.detectionCompleted == false)
        #expect(vm.detectionFailed == false)
        #expect(vm.isAdjustmentPanelVisible == false)
        #expect(vm.defaultStyle == .blurredGlass)
        #expect(vm.defaultShape == .rectangle)
        #expect(vm.draftRevision == 0)
        #expect(vm.renderedRevision == nil)
        #expect(vm.renderedImage == nil)
        #expect(vm.hasDrafts == false)
    }

    // MARK: - Detection

    @Test("Detection maps faces to included ellipse proposals")
    func detectionMapsProposals() async {
        let face = makeFace(x: 0.2, y: 0.3, width: 0.25, height: 0.35)
        let (vm, _) = makeViewModel(faces: [face])
        vm.defaultStyle = .pixelArt

        await vm.detectFaces()

        #expect(vm.regions.count == 1)
        let region = vm.regions[0]
        #expect(region.id == face.id)
        #expect(region.source == .detectedFace)
        #expect(region.shape == .ellipse)
        #expect(rectsAreEqual(region.rect, face.rect))
        #expect(region.isIncluded)
        #expect(region.style == .pixelArt)
        #expect(region.linkedFaceID == face.id)
        #expect(vm.selectedRegionID == face.id)
        #expect(vm.phase == .reviewing)
        #expect(vm.detectionCompleted)
        #expect(vm.detectionFailed == false)
        // Detection is a proposal, not a draft edit.
        #expect(vm.draftRevision == 0)
        #expect(vm.hasDrafts == false)
    }

    @Test("Detection runs only once and never overwrites regions")
    func detectionReentryGuard() async {
        let (vm, _) = makeViewModel(faces: [makeFace()])
        await vm.detectFaces()
        #expect(vm.regions.count == 1)

        // Simulate the user deleting every region, then returning to the screen.
        vm.regions = []
        await vm.detectFaces()

        #expect(vm.regions.isEmpty)
    }

    @Test("Detection failure falls back to review with manual recovery")
    func detectionFailure() async {
        let (vm, _) = makeViewModel(detectionError: RenderFailure())

        await vm.detectFaces()

        #expect(vm.detectionFailed)
        #expect(vm.phase == .reviewing)
        #expect(vm.regions.isEmpty)
        #expect(vm.selectedRegionID == nil)
        #expect(vm.detectionCompleted)
    }

    @Test("Detection with zero faces enters review, not a dead end")
    func detectionZeroFaces() async {
        let (vm, _) = makeViewModel(faces: [])

        await vm.detectFaces()

        #expect(vm.regions.isEmpty)
        #expect(vm.phase == .reviewing)
        #expect(vm.detectionFailed == false)
        #expect(vm.detectionCompleted)
    }

    // MARK: - Inclusion / selection

    @Test("toggleInclusion selects, opens the panel, and bumps the draft")
    func toggleInclusion() async {
        let (vm, _) = makeViewModel(faces: [makeFace(), makeFace(x: 0.6)])
        await vm.detectFaces()
        let id = vm.regions[0].id

        vm.toggleInclusion(id: id)

        #expect(vm.regions[0].isIncluded == false)
        #expect(vm.regions[1].isIncluded == true)
        #expect(vm.selectedRegionID == id)
        #expect(vm.isAdjustmentPanelVisible)
        #expect(vm.phase == .regionSelected)
        #expect(vm.draftRevision == 1)
    }

    @Test("toggleInclusion on an unknown id is a no-op")
    func toggleInclusionUnknownID() async {
        let (vm, _) = makeViewModel(faces: [makeFace()])
        await vm.detectFaces()

        vm.toggleInclusion(id: UUID())

        #expect(vm.regions[0].isIncluded)
        #expect(vm.draftRevision == 0)
    }

    @Test("selectRegion selects without toggling inclusion")
    func selectRegion() async {
        let (vm, _) = makeViewModel(faces: [makeFace(), makeFace(x: 0.6)])
        await vm.detectFaces()
        let second = vm.regions[1].id

        vm.selectRegion(id: second)

        #expect(vm.selectedRegionID == second)
        #expect(vm.phase == .regionSelected)
        #expect(vm.isAdjustmentPanelVisible)
        #expect(vm.regions[1].isIncluded)
        #expect(vm.draftRevision == 0)
    }

    @Test("selectRegion(nil) deselects, hides the panel, and returns to review")
    func selectRegionNil() async {
        let (vm, _) = makeViewModel(faces: [makeFace()])
        await vm.detectFaces()
        vm.selectRegion(id: vm.regions[0].id)

        vm.selectRegion(id: nil)

        #expect(vm.selectedRegionID == nil)
        #expect(vm.isAdjustmentPanelVisible == false)
        #expect(vm.phase == .reviewing)
    }

    // MARK: - Manual regions

    @Test("addManualRegion appends an included manual region and selects it")
    func addManualRegion() {
        let (vm, _) = makeReviewedViewModel()
        vm.defaultStyle = .pixelArt

        let added = vm.addManualRegion(
            normalizedRect: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.2),
            shape: .rectangle
        )

        #expect(added == .added)
        #expect(vm.regions.count == 1)
        let region = vm.regions[0]
        #expect(region.isManual)
        #expect(region.shape == .rectangle)
        #expect(rectsAreEqual(region.rect, CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.2)))
        #expect(region.isIncluded)
        #expect(region.style == .pixelArt)
        #expect(region.sizeMultiplier == 1.0)
        #expect(vm.selectedRegionID == region.id)
        #expect(vm.defaultShape == .rectangle)
        #expect(vm.isAdjustmentPanelVisible)
        #expect(vm.phase == .regionSelected)
        #expect(vm.draftRevision == 1)
    }

    @Test("Circles are stored with a 1:1 rect around the drag center")
    func addManualCircleKeepsSquare() {
        let (vm, _) = makeReviewedViewModel()

        let added = vm.addManualRegion(
            normalizedRect: CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.1),
            shape: .circle
        )

        #expect(added == .added)
        let rect = vm.regions[0].rect
        #expect(rect.width == rect.height)
        #expect(abs(rect.width - 0.4) < 0.0001)
        #expect(abs(rect.midX - 0.4) < 0.0001)
        #expect(abs(rect.midY - 0.25) < 0.0001)
    }

    @Test("Manual regions are clamped into the image")
    func addManualClamps() {
        let (vm, _) = makeReviewedViewModel()

        let added = vm.addManualRegion(
            normalizedRect: CGRect(x: 0.85, y: 0.85, width: 0.4, height: 0.4),
            shape: .ellipse
        )

        #expect(added == .added)
        let rect = vm.regions[0].rect
        #expect(rect.minX >= 0)
        #expect(rect.minY >= 0)
        #expect(rect.maxX <= 1)
        #expect(rect.maxY <= 1)
    }

    @Test("Regions below the minimum size are rejected")
    func addManualRejectsTooSmall() {
        let (vm, _) = makeReviewedViewModel()

        let added = vm.addManualRegion(
            normalizedRect: CGRect(x: 0.2, y: 0.2, width: 0.005, height: 0.005),
            shape: .rectangle
        )

        #expect(added == .tooSmall)
        #expect(vm.regions.isEmpty)
        #expect(vm.draftRevision == 0)
    }

    @Test("Regions at the minimum size are accepted")
    func addManualAcceptsMinimum() {
        let (vm, _) = makeReviewedViewModel()

        #expect(
            vm.addManualRegion(
                normalizedRect: CGRect(
                    x: 0.2,
                    y: 0.2,
                    width: RegionGeometry.minimumNormalizedSize,
                    height: RegionGeometry.minimumNormalizedSize
                ),
                shape: .rectangle
            ) == .added
        )
    }

    @Test("Manual regions are capped at 50")
    func manualRegionCap() {
        let (vm, _) = makeReviewedViewModel()

        for _ in 0..<50 {
            #expect(
                vm.addManualRegion(
                    normalizedRect: CGRect(x: 0.1, y: 0.1, width: 0.05, height: 0.05),
                    shape: .rectangle
                ) == .added
            )
        }

        #expect(
            vm.addManualRegion(
                normalizedRect: CGRect(x: 0.1, y: 0.1, width: 0.05, height: 0.05),
                shape: .rectangle
            ) == .limitReached
        )
        #expect(vm.regions.count == 50)
    }

    // MARK: - Move / resize

    @Test("moveRegion updates a manual region and bumps the draft")
    func moveRegion() {
        let (vm, _) = makeReviewedViewModel()
        addManual(vm, rect: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2))
        let id = vm.regions[0].id
        let revisionBefore = vm.draftRevision

        let moved = vm.moveRegion(id: id, to: CGRect(x: 0.6, y: 0.5, width: 0.2, height: 0.2))

        #expect(moved)
        #expect(rectsAreEqual(vm.regions[0].rect, CGRect(x: 0.6, y: 0.5, width: 0.2, height: 0.2)))
        #expect(vm.draftRevision == revisionBefore + 1)
    }

    @Test("moveRegion clamps the region into the image")
    func moveRegionClamps() {
        let (vm, _) = makeReviewedViewModel()
        addManual(vm, rect: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2))
        let id = vm.regions[0].id

        #expect(vm.moveRegion(id: id, to: CGRect(x: 0.9, y: 0.9, width: 0.2, height: 0.2)))

        let rect = vm.regions[0].rect
        #expect(rect.maxX <= 1)
        #expect(rect.maxY <= 1)
    }

    @Test("Detected faces cannot be moved or resized")
    func facesAreNotDirectlyMovable() async {
        let (vm, _) = makeViewModel(faces: [makeFace()])
        await vm.detectFaces()
        let id = vm.regions[0].id
        let original = vm.regions[0].rect

        #expect(vm.moveRegion(id: id, to: CGRect(x: 0.6, y: 0.6, width: 0.2, height: 0.2)) == false)
        #expect(vm.resizeRegion(id: id, to: CGRect(x: 0.6, y: 0.6, width: 0.2, height: 0.2)) == false)
        #expect(rectsAreEqual(vm.regions[0].rect, original))
    }

    @Test("resizeRegion rejects sizes below the minimum")
    func resizeRejectsTooSmall() {
        let (vm, _) = makeReviewedViewModel()
        addManual(vm)
        let id = vm.regions[0].id
        let original = vm.regions[0].rect
        let revisionBefore = vm.draftRevision

        #expect(vm.resizeRegion(id: id, to: CGRect(x: 0.1, y: 0.1, width: 0.001, height: 0.001)) == false)
        #expect(rectsAreEqual(vm.regions[0].rect, original))
        #expect(vm.draftRevision == revisionBefore)
    }

    @Test("Circle resizing keeps width equal to height")
    func resizeCircleKeepsSquare() {
        let (vm, _) = makeReviewedViewModel()
        addManual(vm, rect: CGRect(x: 0.2, y: 0.2, width: 0.2, height: 0.2), shape: .circle)
        let id = vm.regions[0].id

        #expect(vm.resizeRegion(id: id, to: CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.15)))

        let rect = vm.regions[0].rect
        #expect(rect.width == rect.height)
        #expect(abs(rect.width - 0.4) < 0.0001)
    }

    // MARK: - Shape switching

    @Test("switchShape converts a manual region and updates the drawing default")
    func switchShape() {
        let (vm, _) = makeReviewedViewModel()
        addManual(vm, rect: CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.2), shape: .rectangle)
        let id = vm.regions[0].id
        let revisionBefore = vm.draftRevision

        #expect(vm.switchShape(id: id, to: .circle))

        let rect = vm.regions[0].rect
        #expect(vm.regions[0].shape == .circle)
        #expect(rect.width == rect.height)
        #expect(abs(rect.midX - 0.4) < 0.0001)
        #expect(vm.defaultShape == .circle)
        #expect(vm.selectedRegionID == id)
        #expect(vm.draftRevision == revisionBefore + 1)
    }

    @Test("Detected faces cannot switch shape")
    func faceShapeSwitchRejected() async {
        let (vm, _) = makeViewModel(faces: [makeFace()])
        await vm.detectFaces()
        let id = vm.regions[0].id

        #expect(vm.switchShape(id: id, to: .rectangle) == false)
        #expect(vm.regions[0].shape == .ellipse)
    }

    @Test("shape setter drives either the selected manual region or the default")
    func shapeSetter() {
        let (vm, _) = makeReviewedViewModel()
        vm.shape = .ellipse
        #expect(vm.defaultShape == .ellipse)
        #expect(vm.draftRevision == 0)

        addManual(vm, shape: .rectangle)
        vm.shape = .circle
        #expect(vm.regions[0].shape == .circle)
        #expect(vm.defaultShape == .circle)
    }

    // MARK: - Delete

    @Test("deleteRegion removes the region and clears selection")
    func deleteRegion() {
        let (vm, _) = makeReviewedViewModel()
        addManual(vm)
        let id = vm.regions[0].id
        let revisionBefore = vm.draftRevision

        vm.deleteRegion(id: id)

        #expect(vm.regions.isEmpty)
        #expect(vm.selectedRegionID == nil)
        #expect(vm.isAdjustmentPanelVisible == false)
        #expect(vm.phase == .reviewing)
        #expect(vm.draftRevision == revisionBefore + 1)
    }

    @Test("Deleting a non-selected region keeps the current selection")
    func deleteNonSelectedRegion() {
        let (vm, _) = makeReviewedViewModel()
        addManual(vm, rect: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2))
        addManual(vm, rect: CGRect(x: 0.6, y: 0.6, width: 0.2, height: 0.2))
        let second = vm.regions[1].id
        vm.selectRegion(id: second)

        vm.deleteRegion(id: vm.regions[0].id)

        #expect(vm.regions.count == 1)
        #expect(vm.selectedRegionID == second)
    }

    // MARK: - Styles

    @Test("applyStyle only changes the targeted region")
    func applyStyleTargetsOneRegion() async {
        let (vm, _) = makeViewModel(faces: [makeFace(), makeFace(x: 0.6)])
        await vm.detectFaces()
        let first = vm.regions[0].id

        vm.applyStyle(.pixelArt, to: first)

        #expect(vm.regions[0].style == .pixelArt)
        #expect(vm.regions[1].style == .blurredGlass)
        #expect(vm.defaultStyle == .pixelArt)
        #expect(vm.selectedRegionID == first)
        #expect(vm.draftRevision == 1)
    }

    @Test("applyStyleToAll copies style and emoji to included regions only")
    func applyStyleToAll() async {
        let (vm, _) = makeViewModel(faces: [makeFace(), makeFace(x: 0.6), makeFace(x: 0.8)])
        await vm.detectFaces()
        vm.regions[1].isIncluded = false
        vm.regions[0].selectedEmoji = "🐱"
        vm.regions[0].intensity = 0.4
        vm.regions[2].intensity = 0.9
        vm.selectRegion(id: vm.regions[0].id)

        vm.applyStyleToAll(.solidClean)

        #expect(vm.regions[0].style == .solidClean)
        #expect(vm.regions[2].style == .solidClean)
        #expect(vm.regions[0].selectedEmoji == "🐱")
        #expect(vm.regions[2].selectedEmoji == "🐱")
        // Excluded region and per-region intensity are untouched.
        #expect(vm.regions[1].style == .blurredGlass)
        #expect(vm.regions[0].intensity == 0.4)
        #expect(vm.regions[2].intensity == 0.9)
        #expect(vm.defaultStyle == .solidClean)
    }

    // MARK: - Selected-region proxies

    @Test("intensity, size, and emoji proxy to the selected region")
    func proxies() async {
        let (vm, _) = makeViewModel(faces: [makeFace(), makeFace(x: 0.6)])
        await vm.detectFaces()
        vm.regions[0].intensity = 0.5
        vm.regions[1].intensity = 0.8
        vm.regions[1].sizeMultiplier = 1.5
        vm.selectRegion(id: vm.regions[0].id)

        #expect(vm.intensity == 0.5)
        #expect(vm.sizeMultiplier == 1.0)

        vm.intensity = 0.9
        #expect(vm.regions[0].intensity == 0.9)

        vm.selectRegion(id: vm.regions[1].id)
        #expect(vm.intensity == 0.8)
        #expect(vm.sizeMultiplier == 1.5)

        vm.sizeMultiplier = 2.0
        #expect(vm.regions[1].sizeMultiplier == 2.0)
        #expect(vm.draftRevision == 2)
    }

    @Test("Manual regions ignore sizeMultiplier writes")
    func manualSizeMultiplierIgnored() {
        let (vm, _) = makeReviewedViewModel()
        addManual(vm)
        let revisionBefore = vm.draftRevision

        vm.sizeMultiplier = 2.0

        #expect(vm.regions[0].sizeMultiplier == 1.0)
        #expect(vm.draftRevision == revisionBefore)
    }

    @Test("selectedEmoji proxies to the selected region")
    func emojiProxy() async {
        let (vm, _) = makeViewModel(faces: [makeFace(), makeFace(x: 0.6)])
        await vm.detectFaces()
        vm.selectRegion(id: vm.regions[0].id)
        #expect(vm.selectedEmoji == "😎")

        vm.selectedEmoji = "🐱"
        #expect(vm.regions[0].selectedEmoji == "🐱")

        vm.selectRegion(id: vm.regions[1].id)
        vm.selectedEmoji = "🎭"
        #expect(vm.regions[1].selectedEmoji == "🎭")
    }

    @Test("selectedStyle follows the region, falling back to the default")
    func selectedStyleFallsBack() async {
        let (vm, _) = makeViewModel(faces: [makeFace()])
        await vm.detectFaces()
        vm.regions[0].style = .crystalize
        vm.defaultStyle = .solidClean
        vm.selectRegion(id: vm.regions[0].id)

        #expect(vm.selectedStyle == .crystalize)

        vm.selectRegion(id: nil)
        #expect(vm.selectedStyle == .solidClean)
    }

    // MARK: - Drawing state

    @Test("beginDrawing clears selection and cancelDrawing returns to review")
    func drawingState() async {
        let (vm, _) = makeViewModel(faces: [makeFace()])
        await vm.detectFaces()

        vm.beginDrawing()
        #expect(vm.phase == .drawing)
        #expect(vm.selectedRegionID == nil)
        #expect(vm.isAdjustmentPanelVisible == false)

        vm.cancelDrawing()
        #expect(vm.phase == .reviewing)
    }

    // MARK: - Confirm / render

    @Test("confirm throws .empty when nothing is included and never renders")
    func confirmEmptyThrows() async {
        let (vm, spy) = makeReviewedViewModel()

        await #expect(throws: EditorConfirmError.empty) {
            try await vm.confirm(allowEmpty: false)
        }

        #expect(spy.callCount == 0)
        #expect(vm.renderedImage == nil)
        #expect(vm.phase == .reviewing)
    }

    @Test("confirm with an excluded-only draft throws .empty")
    func confirmAllExcludedThrows() async {
        let (vm, spy) = makeViewModel(faces: [makeFace()])
        await vm.detectFaces()
        vm.toggleInclusion(id: vm.regions[0].id)

        await #expect(throws: EditorConfirmError.empty) {
            try await vm.confirm(allowEmpty: false)
        }

        #expect(spy.callCount == 0)
    }

    @Test("allowEmpty returns the original explicitly without rendering")
    func allowEmptyReturnsOriginal() async throws {
        let source = makeTestImage(size: CGSize(width: 120, height: 80))
        let (vm, spy) = makeViewModel(image: source)
        vm.phase = .reviewing

        let result = try await vm.confirm(allowEmpty: true)

        #expect(result === source)
        #expect(spy.callCount == 0)
        #expect(vm.renderedImage == nil)
    }

    @Test("confirm renders only included regions and caches by revision")
    func confirmRendersAndCaches() async throws {
        let expected = makeTestImage(color: .systemRed)
        let (vm, spy) = makeViewModel(
            faces: [makeFace(), makeFace(x: 0.6)],
            renderResult: expected
        )
        await vm.detectFaces()
        vm.toggleInclusion(id: vm.regions[1].id)

        let first = try await vm.confirm(allowEmpty: false)

        #expect(first === expected)
        #expect(spy.callCount == 1)
        #expect(spy.capturedRegions.count == 1)
        #expect(spy.capturedRegions[0].id == vm.regions[0].id)
        #expect(vm.renderedImage === expected)
        #expect(vm.renderedRevision == vm.draftRevision)
        #expect(vm.phase == .reviewing)

        let second = try await vm.confirm(allowEmpty: false)

        #expect(second === expected)
        #expect(spy.callCount == 1)
    }

    @Test("A draft change invalidates the render cache")
    func draftChangeInvalidatesCache() async throws {
        let (vm, spy) = makeViewModel(faces: [makeFace()])
        await vm.detectFaces()

        _ = try await vm.confirm(allowEmpty: false)
        #expect(spy.callCount == 1)

        vm.intensity = 0.4

        _ = try await vm.confirm(allowEmpty: false)
        #expect(spy.callCount == 2)
        #expect(vm.renderedRevision == vm.draftRevision)
    }

    @Test("Render failure throws and never falls back to the source image")
    func renderFailureHasNoFallback() async {
        let (vm, _) = makeViewModel(faces: [makeFace()], renderError: RenderFailure())
        await vm.detectFaces()

        await #expect(throws: RenderFailure.self) {
            try await vm.confirm(allowEmpty: false)
        }

        #expect(vm.renderedImage == nil)
        #expect(vm.renderedRevision == nil)
        #expect(vm.phase == .reviewing)
    }

    @Test("Changing solidCleanColor invalidates the render cache")
    func solidColorChangeInvalidatesCache() async throws {
        let (vm, spy) = makeViewModel(faces: [makeFace()])
        await vm.detectFaces()

        _ = try await vm.confirm(allowEmpty: false)
        #expect(spy.callCount == 1)
        let revisionBefore = vm.draftRevision

        vm.solidCleanColor = .red
        #expect(vm.draftRevision == revisionBefore + 1)

        // Setting the same color again is not a mutation.
        vm.solidCleanColor = .red
        #expect(vm.draftRevision == revisionBefore + 1)

        _ = try await vm.confirm(allowEmpty: false)
        #expect(spy.callCount == 2)
    }

    @Test("confirm forwards the selected solid color")
    func confirmForwardsSolidColor() async throws {
        let (vm, spy) = makeViewModel(faces: [makeFace()])
        await vm.detectFaces()
        vm.solidCleanColor = .red
        vm.regions[0].style = .solidClean

        _ = try await vm.confirm(allowEmpty: false)

        #expect(spy.capturedColor == UIColor(.red))
    }
}
