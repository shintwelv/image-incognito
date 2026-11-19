//
//  MaskRegionRenderingTests.swift
//  image-incognitoTests
//
//  Pixel-level tests for shape-aware region rendering: rectangles fill their
//  corners, ellipses/circles leave bounding-box corners untouched, excluded
//  regions are skipped, out-of-bounds rects are clamped, and region rendering
//  is independent per region.
//

import CoreGraphics
import Testing
import UIKit
@testable import image_incognito

@MainActor
@Suite("MaskRegionRendering")
struct MaskRegionRenderingTests {

    private let service = MaskRenderingService()
    private let side: CGFloat = 200

    private var red: UIColor { UIColor(red: 1, green: 0, blue: 0, alpha: 1) }
    private var blue: UIColor { UIColor(red: 0, green: 0, blue: 1, alpha: 1) }

    // MARK: - Helpers

    private func makeOpaqueWhiteImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))
        }
    }

    private func makeRegion(
        shape: MaskRegion.Shape,
        rect: CGRect,
        source: MaskRegion.Source = .manual,
        isIncluded: Bool = true,
        intensity: Double = 1.0,
        sizeMultiplier: Double = 1.0
    ) -> MaskRegion {
        MaskRegion(
            source: source,
            shape: shape,
            rect: rect,
            isIncluded: isIncluded,
            style: .solidClean,
            intensity: intensity,
            sizeMultiplier: sizeMultiplier
        )
    }

    /// Samples a single pixel and returns non-premultiplied RGBA components.
    private func rgba(at point: CGPoint, in image: UIImage) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        guard let cgImage = image.cgImage else { return (0, 0, 0, 0) }
        let x = Int(point.x.rounded(.down))
        let y = Int(point.y.rounded(.down))
        guard let cropped = cgImage.cropping(to: CGRect(x: x, y: y, width: 1, height: 1)) else {
            return (0, 0, 0, 0)
        }

        var pixel = [UInt8](repeating: 0, count: 4)
        guard let ctx = CGContext(
            data: &pixel,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return (0, 0, 0, 0)
        }

        ctx.interpolationQuality = .none
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))

        return (
            CGFloat(pixel[0]) / 255,
            CGFloat(pixel[1]) / 255,
            CGFloat(pixel[2]) / 255,
            CGFloat(pixel[3]) / 255
        )
    }

    private func isWhite(_ point: CGPoint, in image: UIImage) -> Bool {
        let p = rgba(at: point, in: image)
        return p.r > 0.9 && p.g > 0.9 && p.b > 0.9
    }

    private func isRed(_ point: CGPoint, in image: UIImage) -> Bool {
        let p = rgba(at: point, in: image)
        return p.r > 0.8 && p.g < 0.2 && p.b < 0.2
    }

    private func isBlue(_ point: CGPoint, in image: UIImage) -> Bool {
        let p = rgba(at: point, in: image)
        return p.b > 0.8 && p.r < 0.2 && p.g < 0.2
    }

    // MARK: - Rectangle

    @Test("Rectangle masks its corners and center")
    func rectangleMasksCorners() async throws {
        let region = makeRegion(shape: .rectangle, rect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))
        let result = try await service.render(
            image: makeOpaqueWhiteImage(),
            regions: [region],
            solidCleanColor: red
        )

        #expect(isRed(CGPoint(x: 52, y: 52), in: result))
        #expect(isRed(CGPoint(x: 147, y: 52), in: result))
        #expect(isRed(CGPoint(x: 52, y: 147), in: result))
        #expect(isRed(CGPoint(x: 147, y: 147), in: result))
        #expect(isRed(CGPoint(x: 100, y: 100), in: result))
        #expect(isWhite(CGPoint(x: 10, y: 10), in: result))
        #expect(isWhite(CGPoint(x: 190, y: 190), in: result))
    }

    // MARK: - Ellipse & circle

    @Test("Ellipse leaves bounding-box corners unmasked but masks the center")
    func ellipseLeavesCornersUnmasked() async throws {
        let region = makeRegion(shape: .ellipse, rect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))
        let result = try await service.render(
            image: makeOpaqueWhiteImage(),
            regions: [region],
            solidCleanColor: red
        )

        #expect(isWhite(CGPoint(x: 52, y: 52), in: result))
        #expect(isWhite(CGPoint(x: 147, y: 52), in: result))
        #expect(isWhite(CGPoint(x: 52, y: 147), in: result))
        #expect(isWhite(CGPoint(x: 147, y: 147), in: result))
        #expect(isRed(CGPoint(x: 100, y: 100), in: result))
        #expect(isRed(CGPoint(x: 100, y: 52), in: result))
    }

    @Test("Circle uses a square bounding box and renders as an oval")
    func circleRendersAsOval() async throws {
        let region = makeRegion(shape: .circle, rect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))
        #expect(region.rect.width == region.rect.height)

        let result = try await service.render(
            image: makeOpaqueWhiteImage(),
            regions: [region],
            solidCleanColor: red
        )

        #expect(isWhite(CGPoint(x: 52, y: 52), in: result))
        #expect(isWhite(CGPoint(x: 147, y: 52), in: result))
        #expect(isWhite(CGPoint(x: 52, y: 147), in: result))
        #expect(isWhite(CGPoint(x: 147, y: 147), in: result))
        #expect(isRed(CGPoint(x: 100, y: 100), in: result))
        #expect(isRed(CGPoint(x: 52, y: 100), in: result))
    }

    @Test("A stretched circle region is squared before rendering")
    func stretchedCircleRegionIsSquared() async throws {
        // Input is 0.5 wide but 0.25 tall; with a fixed center the circle
        // becomes a 0.5 x 0.5 square clamped to the image.
        let region = makeRegion(shape: .circle, rect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.25))
        #expect(region.rect.width == region.rect.height)

        let result = try await service.render(
            image: makeOpaqueWhiteImage(),
            regions: [region],
            solidCleanColor: red
        )

        #expect(isWhite(CGPoint(x: 52, y: 52), in: result))
        #expect(isRed(CGPoint(x: 100, y: 100), in: result))
    }

    // MARK: - Inclusion

    @Test("Excluded regions are not masked")
    func excludedRegionIsSkipped() async throws {
        let region = makeRegion(
            shape: .rectangle,
            rect: CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5),
            isIncluded: false
        )
        let result = try await service.render(
            image: makeOpaqueWhiteImage(),
            regions: [region],
            solidCleanColor: red
        )

        #expect(isWhite(CGPoint(x: 100, y: 100), in: result))
        #expect(isWhite(CGPoint(x: 52, y: 52), in: result))
    }

    // MARK: - Clamping

    @Test("Rects extending past the image are clamped without throwing")
    func outOfBoundsRectIsClamped() async throws {
        let region = makeRegion(shape: .rectangle, rect: CGRect(x: 0.8, y: 0.8, width: 0.5, height: 0.5))
        let result = try await service.render(
            image: makeOpaqueWhiteImage(),
            regions: [region],
            solidCleanColor: red
        )

        #expect(result.size == CGSize(width: side, height: side))
        #expect(isRed(CGPoint(x: 180, y: 180), in: result))
        #expect(isWhite(CGPoint(x: 100, y: 100), in: result))
        #expect(isWhite(CGPoint(x: 10, y: 10), in: result))
    }

    @Test("Fully off-image regions render nothing and do not throw")
    func fullyOffImageRegionIsSafe() async throws {
        let region = makeRegion(shape: .rectangle, rect: CGRect(x: 2, y: 2, width: 0.5, height: 0.5))
        let result = try await service.render(
            image: makeOpaqueWhiteImage(),
            regions: [region],
            solidCleanColor: red
        )

        #expect(isWhite(CGPoint(x: 10, y: 10), in: result))
        #expect(isWhite(CGPoint(x: 190, y: 190), in: result))
    }

    // MARK: - Multiple regions

    @Test("Two solid regions render independently across requested colors")
    func twoSolidRegionsRenderIndependently() async throws {
        let topLeft = makeRegion(shape: .rectangle, rect: CGRect(x: 0.05, y: 0.05, width: 0.2, height: 0.2))
        let bottomRight = makeRegion(shape: .rectangle, rect: CGRect(x: 0.75, y: 0.75, width: 0.2, height: 0.2))
        let regions = [topLeft, bottomRight]
        let gap = CGPoint(x: 100, y: 100)
        let topLeftPoint = CGPoint(x: 30, y: 30)
        let bottomRightPoint = CGPoint(x: 170, y: 170)

        let redResult = try await service.render(
            image: makeOpaqueWhiteImage(),
            regions: regions,
            solidCleanColor: red
        )
        #expect(isRed(topLeftPoint, in: redResult))
        #expect(isRed(bottomRightPoint, in: redResult))
        #expect(isWhite(gap, in: redResult))

        let blueResult = try await service.render(
            image: makeOpaqueWhiteImage(),
            regions: regions,
            solidCleanColor: blue
        )
        #expect(isBlue(topLeftPoint, in: blueResult))
        #expect(isBlue(bottomRightPoint, in: blueResult))
        #expect(isWhite(gap, in: blueResult))
    }

    // MARK: - sizeMultiplier

    @Test("sizeMultiplier expands detected faces but not manual regions")
    func sizeMultiplierAppliesOnlyToFaces() async throws {
        let face = makeRegion(
            shape: .ellipse,
            rect: CGRect(x: 0.375, y: 0.375, width: 0.25, height: 0.25),
            source: .detectedFace,
            sizeMultiplier: 2.0
        )
        let manual = makeRegion(
            shape: .ellipse,
            rect: CGRect(x: 0.375, y: 0.375, width: 0.25, height: 0.25),
            source: .manual,
            sizeMultiplier: 2.0
        )

        let faceResult = try await service.render(
            image: makeOpaqueWhiteImage(),
            regions: [face],
            solidCleanColor: red
        )
        let manualResult = try await service.render(
            image: makeOpaqueWhiteImage(),
            regions: [manual],
            solidCleanColor: red
        )

        // Face ellipse doubled to 0.5 x 0.5 reaches (0.25...0.75); the
        // unexpanded manual ellipse stays within (0.375...0.625).
        #expect(isRed(CGPoint(x: 60, y: 100), in: faceResult))
        #expect(isWhite(CGPoint(x: 60, y: 100), in: manualResult))
        #expect(isRed(CGPoint(x: 100, y: 100), in: manualResult))
    }
}
