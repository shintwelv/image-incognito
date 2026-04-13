//
//  FaceSelectionHitTesterTests.swift
//  image-incognitoTests
//
//  Unit tests for FaceSelectionHitTester: verifies hit-testing priority,
//  rendered image geometry, and overlay scaling behavior.
//

import CoreGraphics
import Foundation
import Testing
@testable import image_incognito

@Suite("FaceSelectionHitTester")
struct FaceSelectionHitTesterTests {

    private func makeFace(
        id: UUID = UUID(),
        x: CGFloat = 0.1,
        y: CGFloat = 0.2,
        width: CGFloat = 0.2,
        height: CGFloat = 0.2,
        isMasked: Bool = true
    ) -> FaceBox {
        FaceBox(
            id: id,
            rect: CGRect(x: x, y: y, width: width, height: height),
            isMasked: isMasked
        )
    }

    @Test("faceID returns the matching face when the tap lands inside an overlay")
    func faceIDInsideOverlay() {
        let face = makeFace()
        let imageRect = CGRect(x: 0, y: 0, width: 300, height: 200)

        let tappedID = FaceSelectionHitTester.faceID(
            at: CGPoint(x: 45, y: 60),
            faces: [face],
            imageRect: imageRect,
            sizeMultiplier: 1.0
        )

        #expect(tappedID == face.id)
    }

    @Test("faceID returns nil for taps outside the rendered image")
    func faceIDOutsideImageRect() {
        let tappedID = FaceSelectionHitTester.faceID(
            at: CGPoint(x: 10, y: 10),
            faces: [makeFace()],
            imageRect: CGRect(x: 50, y: 50, width: 200, height: 200),
            sizeMultiplier: 1.0
        )

        #expect(tappedID == nil)
    }

    @Test("faceID returns nil when no overlays contain the point")
    func faceIDOutsideOverlay() {
        let tappedID = FaceSelectionHitTester.faceID(
            at: CGPoint(x: 290, y: 190),
            faces: [makeFace()],
            imageRect: CGRect(x: 0, y: 0, width: 300, height: 200),
            sizeMultiplier: 1.0
        )

        #expect(tappedID == nil)
    }

    @Test("faceID returns nil when the face list is empty")
    func faceIDEmptyFaces() {
        let tappedID = FaceSelectionHitTester.faceID(
            at: CGPoint(x: 50, y: 50),
            faces: [],
            imageRect: CGRect(x: 0, y: 0, width: 200, height: 200),
            sizeMultiplier: 1.0
        )

        #expect(tappedID == nil)
    }

    @Test("faceID prioritizes the last face in the array when overlays overlap")
    func faceIDPrioritizesTopmostFace() {
        let first = makeFace(id: UUID(), x: 0.2, y: 0.2, width: 0.3, height: 0.3)
        let second = makeFace(id: UUID(), x: 0.2, y: 0.2, width: 0.3, height: 0.3)
        let tappedID = FaceSelectionHitTester.faceID(
            at: CGPoint(x: 90, y: 90),
            faces: [first, second],
            imageRect: CGRect(x: 0, y: 0, width: 300, height: 300),
            sizeMultiplier: 1.0
        )

        #expect(tappedID == second.id)
    }

    @Test("faceID respects sizeMultiplier for masked overlays")
    func faceIDRespectsSizeMultiplier() {
        let face = makeFace(x: 0.4, y: 0.4, width: 0.1, height: 0.1, isMasked: true)
        let imageRect = CGRect(x: 0, y: 0, width: 200, height: 200)
        let pointJustOutsideBase = CGPoint(x: 76, y: 100)

        let withoutExpansion = FaceSelectionHitTester.faceID(
            at: pointJustOutsideBase,
            faces: [face],
            imageRect: imageRect,
            sizeMultiplier: 1.0
        )
        let withExpansion = FaceSelectionHitTester.faceID(
            at: pointJustOutsideBase,
            faces: [face],
            imageRect: imageRect,
            sizeMultiplier: 1.5
        )

        #expect(withoutExpansion == nil)
        #expect(withExpansion == face.id)
    }

    @Test("imageRenderRect letterboxes a portrait image in a landscape container")
    func imageRenderRectPortraitInLandscape() {
        let rect = FaceSelectionHitTester.imageRenderRect(
            in: CGSize(width: 300, height: 200),
            imageSize: CGSize(width: 100, height: 200)
        )

        #expect(rect.width == 100)
        #expect(rect.height == 200)
        #expect(rect.minX == 100)
        #expect(rect.minY == 0)
    }

    @Test("imageRenderRect pillarboxes a landscape image in a portrait container")
    func imageRenderRectLandscapeInPortrait() {
        let rect = FaceSelectionHitTester.imageRenderRect(
            in: CGSize(width: 200, height: 300),
            imageSize: CGSize(width: 200, height: 100)
        )

        #expect(rect.width == 200)
        #expect(rect.height == 100)
        #expect(rect.minX == 0)
        #expect(rect.minY == 100)
    }

    @Test("imageRenderRect returns the full container for square content in a square container")
    func imageRenderRectSquare() {
        let container = CGSize(width: 240, height: 240)
        let rect = FaceSelectionHitTester.imageRenderRect(
            in: container,
            imageSize: CGSize(width: 100, height: 100)
        )

        #expect(rect == CGRect(origin: .zero, size: container))
    }

    @Test("imageRenderRect falls back to the container when the image size is invalid")
    func imageRenderRectInvalidImageSize() {
        let container = CGSize(width: 320, height: 180)
        let rect = FaceSelectionHitTester.imageRenderRect(
            in: container,
            imageSize: .zero
        )

        #expect(rect == CGRect(origin: .zero, size: container))
    }

    @Test("overlayFrame maps a normalized face rect into the rendered image space")
    func overlayFrameMapsToImageRect() {
        let frame = FaceSelectionHitTester.overlayFrame(
            for: makeFace(x: 0.1, y: 0.2, width: 0.25, height: 0.5),
            imageRect: CGRect(x: 20, y: 40, width: 200, height: 100),
            sizeMultiplier: 1.0
        )

        #expect(frame == CGRect(x: 40, y: 60, width: 50, height: 50))
    }

    @Test("overlayFrame scales masked overlays around their center")
    func overlayFrameScalesAroundCenter() {
        let frame = FaceSelectionHitTester.overlayFrame(
            for: makeFace(x: 0.2, y: 0.3, width: 0.2, height: 0.2, isMasked: true),
            imageRect: CGRect(x: 0, y: 0, width: 200, height: 200),
            sizeMultiplier: 1.5
        )

        #expect(frame == CGRect(x: 30, y: 50, width: 60, height: 60))
    }

    @Test("overlayFrame ignores sizeMultiplier for unmasked faces")
    func overlayFrameIgnoresSizeMultiplierForUnmaskedFaces() {
        let frame = FaceSelectionHitTester.overlayFrame(
            for: makeFace(x: 0.2, y: 0.3, width: 0.2, height: 0.2, isMasked: false),
            imageRect: CGRect(x: 0, y: 0, width: 200, height: 200),
            sizeMultiplier: 2.0
        )

        #expect(frame == CGRect(x: 40, y: 60, width: 40, height: 40))
    }
}
