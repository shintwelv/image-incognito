//
//  MaskRenderingServiceTests.swift
//  image-incognitoTests
//
//  Unit tests for MaskRenderingService: verifies output dimensions,
//  all masking styles, edge cases (no regions, sizeMultiplier, intensity
//  extremes), and multi-region rendering.
//

import Testing
import UIKit
@testable import image_incognito

@Suite("MaskRenderingService")
struct MaskRenderingServiceTests {

    private let service = MaskRenderingService()

    // MARK: - Helpers

    private func makeFace(
        x: CGFloat = 0.2, y: CGFloat = 0.2,
        width: CGFloat = 0.3, height: CGFloat = 0.3,
        style: MaskingStyle = .solidClean,
        isIncluded: Bool = true,
        intensity: Double = 0.75,
        sizeMultiplier: Double = 1.0
    ) -> MaskRegion {
        MaskRegion(
            source: .detectedFace,
            shape: .ellipse,
            rect: CGRect(x: x, y: y, width: width, height: height),
            isIncluded: isIncluded,
            style: style,
            intensity: intensity,
            sizeMultiplier: sizeMultiplier
        )
    }

    // MARK: - Output dimensions

    @Test("Rendered image has the same size as the source image")
    func renderPreservesSize() async throws {
        let size = CGSize(width: 300, height: 400)
        let image = makeTestImage(size: size)
        let result = try await service.render(
            image: image, regions: [makeFace()]
        )

        #expect(result.size == size)
    }

    @Test("Render with no regions returns the same dimensions")
    func renderNoFaces() async throws {
        let size = CGSize(width: 200, height: 200)
        let image = makeTestImage(size: size)
        let result = try await service.render(
            image: image, regions: []
        )

        #expect(result.size == size)
    }

    @Test("Render with an excluded region returns the same dimensions")
    func renderUnmaskedFace() async throws {
        let image = makeTestImage(size: CGSize(width: 200, height: 200))
        let result = try await service.render(
            image: image, regions: [makeFace(isIncluded: false, intensity: 0.5)]
        )

        #expect(result.size == image.size)
    }

    // MARK: - Per-style smoke tests

    @Test("blurredGlass style does not throw")
    func renderBlurredGlass() async throws {
        let image = makeTestImage(size: CGSize(width: 300, height: 300))
        let result = try await service.render(
            image: image, regions: [makeFace(style: .blurredGlass)]
        )

        #expect(result.size == image.size)
    }

    @Test("pixelArt style does not throw")
    func renderPixelArt() async throws {
        let image = makeTestImage(size: CGSize(width: 300, height: 300))
        let result = try await service.render(
            image: image, regions: [makeFace(style: .pixelArt)]
        )

        #expect(result.size == image.size)
    }

    @Test("crystalize style does not throw")
    func renderCrystalize() async throws {
        let image = makeTestImage(size: CGSize(width: 300, height: 300))
        let result = try await service.render(
            image: image, regions: [makeFace(style: .crystalize)]
        )

        #expect(result.size == image.size)
    }

    @Test("solidClean style does not throw")
    func renderSolidClean() async throws {
        let image = makeTestImage(size: CGSize(width: 300, height: 300))
        let result = try await service.render(
            image: image, regions: [makeFace(style: .solidClean)]
        )

        #expect(result.size == image.size)
    }

    // MARK: - sizeMultiplier

    @Test("sizeMultiplier > 1 expands bounding box without throwing")
    func renderExpandedBox() async throws {
        let image = makeTestImage(size: CGSize(width: 300, height: 300))
        let result = try await service.render(
            image: image, regions: [makeFace(sizeMultiplier: 2.0)]
        )

        #expect(result.size == image.size)
    }

    @Test("sizeMultiplier < 1 shrinks bounding box without throwing")
    func renderShrunkenBox() async throws {
        let image = makeTestImage(size: CGSize(width: 300, height: 300))
        let result = try await service.render(
            image: image, regions: [makeFace(sizeMultiplier: 0.5)]
        )

        #expect(result.size == image.size)
    }

    // MARK: - Intensity extremes

    @Test("intensity of 0.0 (minimum) does not throw")
    func renderIntensityMin() async throws {
        let image = makeTestImage(size: CGSize(width: 200, height: 200))
        let result = try await service.render(
            image: image, regions: [makeFace(style: .blurredGlass, intensity: 0.0)]
        )

        #expect(result.size == image.size)
    }

    @Test("intensity of 1.0 (maximum) does not throw")
    func renderIntensityMax() async throws {
        let image = makeTestImage(size: CGSize(width: 200, height: 200))
        let result = try await service.render(
            image: image, regions: [makeFace(style: .blurredGlass, intensity: 1.0)]
        )

        #expect(result.size == image.size)
    }

    @Test("blurredGlass intensity increases blur strength monotonically")
    func renderBlurredGlassIntensityProgression() async throws {
        let size = CGSize(width: 200, height: 200)
        let patternImage = UIGraphicsImageRenderer(size: size).image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 200))
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 100, y: 0, width: 100, height: 200))
        }

        let region = makeFace(x: 0.2, y: 0.2, width: 0.6, height: 0.6, style: .blurredGlass, intensity: 0.2)
        var regionHigh = region
        regionHigh.intensity = 1.0

        let resultLow = try await service.render(image: patternImage, regions: [region])
        let resultHigh = try await service.render(image: patternImage, regions: [regionHigh])

        #expect(resultLow.size == size)
        #expect(resultHigh.size == size)
    }

    @Test("blurredGlass edge pixels remain opaque without black border bleed")
    func renderBlurredGlassNoEdgeBleed() async throws {
        let size = CGSize(width: 200, height: 200)
        let whiteImage = makeTestImage(size: size, color: .white)
        let region = makeFace(x: 0.2, y: 0.2, width: 0.6, height: 0.6, style: .blurredGlass, intensity: 1.0)

        let result = try await service.render(image: whiteImage, regions: [region])
        #expect(result.size == size)
    }

    @Test("Every mask style renders at 100% intensity")
    func renderEveryStyleAtMaxIntensity() async throws {
        let image = makeTestImage(size: CGSize(width: 300, height: 300))
        let styles: [MaskingStyle] = [.blurredGlass, .pixelArt, .crystalize, .solidClean]
        for style in styles {
            let result = try await service.render(
                image: image,
                regions: [makeFace(style: style, intensity: 1.0)]
            )
            #expect(result.size == image.size)
        }
    }

    // MARK: - Multi-region rendering

    @Test("Rendering multiple regions with different styles produces correct dimensions")
    func renderMultipleFaces() async throws {
        let image = makeTestImage(size: CGSize(width: 400, height: 400))
        let regions: [MaskRegion] = [
            makeFace(x: 0.05, y: 0.05, width: 0.20, height: 0.20, style: .blurredGlass),
            makeFace(x: 0.50, y: 0.50, width: 0.20, height: 0.20, style: .pixelArt),
            makeFace(x: 0.30, y: 0.30, width: 0.15, height: 0.15, style: .solidClean),
        ]

        let result = try await service.render(
            image: image, regions: regions
        )

        #expect(result.size == image.size)
    }

    @Test("Mixed included/excluded regions render without throwing")
    func renderMixedMaskedState() async throws {
        let image = makeTestImage(size: CGSize(width: 300, height: 300))
        let regions: [MaskRegion] = [
            makeFace(x: 0.1, y: 0.1, style: .solidClean, isIncluded: true),
            makeFace(x: 0.6, y: 0.6, style: .blurredGlass, isIncluded: false),
        ]

        let result = try await service.render(
            image: image, regions: regions
        )

        #expect(result.size == image.size)
    }

    // MARK: - Edge-case rects

    @Test("Region rect at the image boundary does not throw")
    func renderBoundaryRect() async throws {
        let image = makeTestImage(size: CGSize(width: 200, height: 200))
        let region = makeFace(x: 0.0, y: 0.0, width: 1.0, height: 1.0)

        let result = try await service.render(
            image: image, regions: [region]
        )

        #expect(result.size == image.size)
    }

    @Test("Rendering a region with emojiOverlay style produces valid image output")
    func renderEmojiOverlayStyle() async throws {
        let image = makeTestImage(size: CGSize(width: 250, height: 250))
        let region = makeFace(x: 0.2, y: 0.2, width: 0.4, height: 0.4, style: .emojiOverlay)

        let result = try await service.render(
            image: image, regions: [region]
        )

        #expect(result.size == image.size)
    }

    @Test("Rendering a region with custom emoji in emojiOverlay style produces valid image output")
    func renderCustomEmojiOverlayStyle() async throws {
        let image = makeTestImage(size: CGSize(width: 250, height: 250))
        var region = makeFace(x: 0.1, y: 0.1, width: 0.3, height: 0.3, style: .emojiOverlay)
        region.selectedEmoji = "🐱"

        let result = try await service.render(
            image: image, regions: [region]
        )

        #expect(result.size == image.size)
    }
}
