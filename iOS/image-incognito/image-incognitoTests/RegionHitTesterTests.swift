//
//  RegionHitTesterTests.swift
//  image-incognitoTests
//
//  Unit tests for RegionHitTester: rendered image geometry, shape-aware hit
//  testing, top-most priority, and overlay scaling behavior.
//

import CoreGraphics
import Foundation
import Testing
@testable import image_incognito

@Suite("RegionHitTester")
struct RegionHitTesterTests {

    private func makeRegion(
        id: UUID = UUID(),
        source: MaskRegion.Source = .manual,
        shape: MaskRegion.Shape = .rectangle,
        x: CGFloat = 0.1,
        y: CGFloat = 0.2,
        width: CGFloat = 0.2,
        height: CGFloat = 0.2,
        isIncluded: Bool = true,
        sizeMultiplier: Double = 1.0
    ) -> MaskRegion {
        MaskRegion(
            id: id,
            source: source,
            shape: shape,
            rect: CGRect(x: x, y: y, width: width, height: height),
            isIncluded: isIncluded,
            sizeMultiplier: sizeMultiplier
        )
    }

    // MARK: - Hit testing

    @Test("regionID returns the matching region when the tap lands inside")
    func regionIDInsideOverlay() {
        let region = makeRegion(shape: .rectangle)
        let imageRect = CGRect(x: 0, y: 0, width: 300, height: 200)

        #expect(
            RegionHitTester.regionID(
                at: CGPoint(x: 45, y: 60),
                regions: [region],
                imageRect: imageRect
            ) == region.id
        )
    }

    @Test("regionID returns nil for taps outside the rendered image")
    func regionIDOutsideImageRect() {
        #expect(
            RegionHitTester.regionID(
                at: CGPoint(x: 10, y: 10),
                regions: [makeRegion()],
                imageRect: CGRect(x: 50, y: 50, width: 200, height: 200)
            ) == nil
        )
    }

    @Test("regionID returns nil when no region contains the point")
    func regionIDOutsideOverlay() {
        #expect(
            RegionHitTester.regionID(
                at: CGPoint(x: 290, y: 190),
                regions: [makeRegion()],
                imageRect: CGRect(x: 0, y: 0, width: 300, height: 200)
            ) == nil
        )
    }

    @Test("regionID returns nil when the region list is empty")
    func regionIDEmpty() {
        #expect(
            RegionHitTester.regionID(
                at: CGPoint(x: 50, y: 50),
                regions: [],
                imageRect: CGRect(x: 0, y: 0, width: 200, height: 200)
            ) == nil
        )
    }

    @Test("regionID prioritizes the last region in the array when overlays overlap")
    func regionIDPrioritizesTopmostRegion() {
        let first = makeRegion(x: 0.2, y: 0.2, width: 0.3, height: 0.3)
        let second = makeRegion(x: 0.2, y: 0.2, width: 0.3, height: 0.3)

        #expect(
            RegionHitTester.regionID(
                at: CGPoint(x: 90, y: 90),
                regions: [first, second],
                imageRect: CGRect(x: 0, y: 0, width: 300, height: 300)
            ) == second.id
        )
    }

    @Test("Rectangle hit testing includes bounding-box corners")
    func rectangleHitsCorner() {
        let region = makeRegion(shape: .rectangle, x: 0.2, y: 0.2, width: 0.4, height: 0.4)
        let imageRect = CGRect(x: 0, y: 0, width: 100, height: 100)

        #expect(
            RegionHitTester.regionID(at: CGPoint(x: 21, y: 21), regions: [region], imageRect: imageRect) == region.id
        )
    }

    @Test("Ellipse and circle hit testing exclude bounding-box corners")
    func ellipseAndCircleExcludeCorners() {
        let imageRect = CGRect(x: 0, y: 0, width: 100, height: 100)
        let ellipse = makeRegion(shape: .ellipse, x: 0.2, y: 0.2, width: 0.4, height: 0.4)
        let circle = makeRegion(shape: .circle, x: 0.2, y: 0.2, width: 0.4, height: 0.4)

        #expect(
            RegionHitTester.regionID(at: CGPoint(x: 21, y: 21), regions: [ellipse], imageRect: imageRect) == nil
        )
        #expect(
            RegionHitTester.regionID(at: CGPoint(x: 21, y: 21), regions: [circle], imageRect: imageRect) == nil
        )
        #expect(
            RegionHitTester.regionID(at: CGPoint(x: 40, y: 40), regions: [ellipse], imageRect: imageRect) == ellipse.id
        )
    }

    @Test("regionID respects sizeMultiplier for detected faces")
    func regionIDRespectsSizeMultiplier() {
        let base = makeRegion(source: .detectedFace, shape: .ellipse, x: 0.4, y: 0.4, width: 0.1, height: 0.1)
        let imageRect = CGRect(x: 0, y: 0, width: 200, height: 200)
        let pointJustOutsideBase = CGPoint(x: 78, y: 90)

        #expect(
            RegionHitTester.regionID(at: pointJustOutsideBase, regions: [base], imageRect: imageRect) == nil
        )

        let expanded = makeRegion(
            source: .detectedFace,
            shape: .ellipse,
            x: 0.4,
            y: 0.4,
            width: 0.1,
            height: 0.1,
            sizeMultiplier: 1.5
        )
        #expect(
            RegionHitTester.regionID(at: pointJustOutsideBase, regions: [expanded], imageRect: imageRect) == expanded.id
        )
    }

    // MARK: - imageRenderRect

    @Test("imageRenderRect letterboxes a portrait image in a landscape container")
    func imageRenderRectPortraitInLandscape() {
        let rect = RegionHitTester.imageRenderRect(
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
        let rect = RegionHitTester.imageRenderRect(
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
        let rect = RegionHitTester.imageRenderRect(
            in: container,
            imageSize: CGSize(width: 100, height: 100)
        )

        #expect(rect == CGRect(origin: .zero, size: container))
    }

    @Test("imageRenderRect falls back to the container when the image size is invalid")
    func imageRenderRectInvalidImageSize() {
        let container = CGSize(width: 320, height: 180)
        let rect = RegionHitTester.imageRenderRect(
            in: container,
            imageSize: .zero
        )

        #expect(rect == CGRect(origin: .zero, size: container))
    }

    // MARK: - overlayFrame

    @Test("overlayFrame maps a normalized region rect into the rendered image space")
    func overlayFrameMapsToImageRect() {
        let frame = RegionHitTester.overlayFrame(
            for: makeRegion(x: 0.1, y: 0.2, width: 0.25, height: 0.5),
            imageRect: CGRect(x: 20, y: 40, width: 200, height: 100)
        )

        #expect(rectsAreEqual(frame, CGRect(x: 40, y: 60, width: 50, height: 50)))
    }

    @Test("overlayFrame scales detected faces around their center")
    func overlayFrameScalesAroundCenter() {
        let frame = RegionHitTester.overlayFrame(
            for: makeRegion(
                source: .detectedFace,
                shape: .ellipse,
                x: 0.2,
                y: 0.3,
                width: 0.2,
                height: 0.2,
                sizeMultiplier: 1.5
            ),
            imageRect: CGRect(x: 0, y: 0, width: 200, height: 200)
        )

        #expect(rectsAreEqual(frame, CGRect(x: 30, y: 50, width: 60, height: 60)))
    }

    @Test("overlayFrame ignores sizeMultiplier for manual regions")
    func overlayFrameIgnoresSizeMultiplierForManualRegions() {
        let frame = RegionHitTester.overlayFrame(
            for: makeRegion(x: 0.2, y: 0.3, width: 0.2, height: 0.2, sizeMultiplier: 2.0),
            imageRect: CGRect(x: 0, y: 0, width: 200, height: 200)
        )

        #expect(rectsAreEqual(frame, CGRect(x: 40, y: 60, width: 40, height: 40)))
    }
}
