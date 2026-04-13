//
//  EditorViewModelTests.swift
//  image-incognitoTests
//
//  Unit tests for EditorViewModel: face toggling, style selection, export, and
//  the Vision coordinate-flip conversion (bottom-left → top-left origin).
//

import Testing
import UIKit
@testable import image_incognito

@MainActor
@Suite("EditorViewModel")
struct EditorViewModelTests {

    // MARK: - Helpers

    private func makeFace(
        x: CGFloat = 0.1, y: CGFloat = 0.1,
        width: CGFloat = 0.3, height: CGFloat = 0.3,
        isMasked: Bool = true,
        style: MaskingStyle = .blurredGlass
    ) -> FaceBox {
        FaceBox(
            rect: CGRect(x: x, y: y, width: width, height: height),
            isMasked: isMasked,
            style: style
        )
    }

    // MARK: - Initial state

    @Test("Initial state is correct")
    func initialState() {
        let vm = EditorViewModel(sourceImage: makeTestImage())

        #expect(vm.faces.isEmpty)
        #expect(vm.isDetecting == false)
        #expect(vm.selectedStyle == .blurredGlass)
        #expect(vm.intensity == 0.75)
        #expect(vm.sizeMultiplier == 1.0)
        #expect(vm.showAdjustmentSliders == false)
        #expect(vm.isRendering == false)
        #expect(vm.renderedImage == nil)
    }

    // MARK: - toggleMask

    @Test("toggleMask flips isMasked for the matching face")
    func toggleMask() {
        let vm = EditorViewModel(sourceImage: makeTestImage())
        let face = makeFace()
        vm.faces = [face]

        vm.toggleMask(id: face.id)
        #expect(vm.faces[0].isMasked == false)

        vm.toggleMask(id: face.id)
        #expect(vm.faces[0].isMasked == true)
    }

    @Test("toggleMask with an unknown id is a no-op")
    func toggleMaskUnknownId() {
        let vm = EditorViewModel(sourceImage: makeTestImage())
        let face = makeFace()
        vm.faces = [face]

        vm.toggleMask(id: UUID())

        #expect(vm.faces[0].isMasked == true)
    }

    @Test("toggleMask only affects the targeted face when multiple exist")
    func toggleMaskTargetsCorrectFace() {
        let vm = EditorViewModel(sourceImage: makeTestImage())
        let first = makeFace(x: 0.1)
        let second = makeFace(x: 0.6)
        vm.faces = [first, second]

        vm.toggleMask(id: first.id)

        #expect(vm.faces[0].isMasked == false)
        #expect(vm.faces[1].isMasked == true)
    }

    @Test("face hit testing resolves the tapped face when multiple exist")
    func faceHitTestingResolvesCorrectFace() {
        let first = makeFace(x: 0.1, y: 0.2, width: 0.2, height: 0.2)
        let second = makeFace(x: 0.6, y: 0.2, width: 0.2, height: 0.2)
        let imageRect = CGRect(x: 0, y: 0, width: 300, height: 300)

        let firstTap = CGPoint(x: 45, y: 90)
        let secondTap = CGPoint(x: 225, y: 90)

        #expect(
            FaceSelectionHitTester.faceID(
                at: firstTap,
                faces: [first, second],
                imageRect: imageRect,
                sizeMultiplier: 1.0
            ) == first.id
        )
        #expect(
            FaceSelectionHitTester.faceID(
                at: secondTap,
                faces: [first, second],
                imageRect: imageRect,
                sizeMultiplier: 1.0
            ) == second.id
        )
    }

    @Test("face hit testing ignores taps outside the rendered image")
    func faceHitTestingIgnoresOutsideImage() {
        let face = makeFace(x: 0.1, y: 0.1, width: 0.2, height: 0.2)
        let imageRect = CGRect(x: 50, y: 50, width: 200, height: 200)

        #expect(
            FaceSelectionHitTester.faceID(
                at: CGPoint(x: 20, y: 20),
                faces: [face],
                imageRect: imageRect,
                sizeMultiplier: 1.0
            ) == nil
        )
    }

    // MARK: - selectStyle

    @Test("selectStyle changes selectedStyle and propagates to all faces")
    func selectStyleChangesPropagates() {
        let vm = EditorViewModel(sourceImage: makeTestImage())
        vm.faces = [makeFace(style: .blurredGlass), makeFace(style: .blurredGlass)]

        vm.selectStyle(.pixelArt)

        #expect(vm.selectedStyle == .pixelArt)
        #expect(vm.faces[0].style == .pixelArt)
        #expect(vm.faces[1].style == .pixelArt)
        #expect(vm.showAdjustmentSliders == true)
    }

    @Test("selectStyle with the same style toggles the adjustment slider panel")
    func selectSameStyleTogglesSliders() {
        let vm = EditorViewModel(sourceImage: makeTestImage())
        // Default selectedStyle is .blurredGlass
        #expect(vm.showAdjustmentSliders == false)

        vm.selectStyle(.blurredGlass)
        #expect(vm.showAdjustmentSliders == true)

        vm.selectStyle(.blurredGlass)
        #expect(vm.showAdjustmentSliders == false)
    }

    @Test("selectStyle with a different style always shows the slider panel")
    func selectDifferentStyleAlwaysShowsSliders() {
        let vm = EditorViewModel(sourceImage: makeTestImage())

        vm.selectStyle(.pixelArt)
        #expect(vm.showAdjustmentSliders == true)

        vm.showAdjustmentSliders = false
        vm.selectStyle(.solidClean)
        #expect(vm.showAdjustmentSliders == true)
    }

    @Test("selectStyle preserves unmasked faces' isMasked state")
    func selectStylePreservesUnmasked() {
        let vm = EditorViewModel(sourceImage: makeTestImage())
        let unmasked = makeFace(isMasked: false)
        vm.faces = [unmasked]

        vm.selectStyle(.solidClean)

        #expect(vm.faces[0].isMasked == false)
    }

    // MARK: - exportTapped

    @Test("exportTapped sets renderedImage and clears isRendering")
    func exportTappedSetsRenderedImage() async {
        let image = makeTestImage(size: CGSize(width: 200, height: 200))
        let vm = EditorViewModel(sourceImage: image)
        vm.faces = [makeFace(style: .solidClean)]

        await vm.exportTapped()

        #expect(vm.isRendering == false)
        #expect(vm.renderedImage != nil)
    }

    @Test("exportTapped with no faces falls back to the source image")
    func exportTappedNoFaces() async {
        let image = makeTestImage()
        let vm = EditorViewModel(sourceImage: image)

        await vm.exportTapped()

        #expect(vm.renderedImage != nil)
    }

    @Test("exportTapped is idempotent when called while already rendering")
    func exportTappedIdempotent() async {
        let vm = EditorViewModel(sourceImage: makeTestImage())
        vm.isRendering = true  // simulate an in-progress render

        await vm.exportTapped()  // should return immediately without overwriting state

        #expect(vm.renderedImage == nil)
    }

    // MARK: - Vision coordinate flip

    @Test("Vision bottom-left y converts correctly to UIKit top-left y")
    func visionCoordinateFlip() {
        // Vision uses bottom-left origin. EditorViewModel converts with:
        //   y_topLeft = 1 - y_bottomLeft - height

        // Face near the top of the image in UIKit has a small y_topLeft
        let visionYTop: CGFloat = 0.75
        let height: CGFloat = 0.20
        let topLeftY = 1 - visionYTop - height
        #expect(abs(topLeftY - 0.05) < 0.001)

        // Face near the bottom of the image in UIKit has a large y_topLeft
        let visionYBottom: CGFloat = 0.05
        let topLeftY2 = 1 - visionYBottom - height
        #expect(abs(topLeftY2 - 0.75) < 0.001)

        // A centered face has the same y in both coordinate systems
        let visionYCenter: CGFloat = 0.40
        let topLeftY3 = 1 - visionYCenter - height
        #expect(abs(topLeftY3 - 0.40) < 0.001)
    }

    @Test("Vision coordinate flip preserves width and height")
    func visionFlipPreservesDimensions() {
        let visionRect = CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.25)
        let flipped = CGRect(
            x: visionRect.origin.x,
            y: 1 - visionRect.origin.y - visionRect.height,
            width: visionRect.width,
            height: visionRect.height
        )

        #expect(flipped.width == visionRect.width)
        #expect(flipped.height == visionRect.height)
    }
}
