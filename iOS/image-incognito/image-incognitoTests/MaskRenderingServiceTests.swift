//
//  MaskRenderingServiceTests.swift
//  image-incognitoTests
//
//  Unit tests for MaskRenderingService: verifies output dimensions,
//  all three masking styles, edge cases (no faces, sizeMultiplier, intensity
//  extremes), and multi-face rendering.
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
        isMasked: Bool = true,
        intensity: Double = 0.75,
        sizeMultiplier: Double = 1.0
    ) -> FaceBox {
        FaceBox(
            rect: CGRect(x: x, y: y, width: width, height: height),
            isMasked: isMasked,
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
            image: image, faces: [makeFace()]
        )

        #expect(result.size == size)
    }

    @Test("Render with no faces returns the same dimensions")
    func renderNoFaces() async throws {
        let size = CGSize(width: 200, height: 200)
        let image = makeTestImage(size: size)
        let result = try await service.render(
            image: image, faces: []
        )

        #expect(result.size == size)
    }

    @Test("Render with an unmasked face returns the same dimensions")
    func renderUnmaskedFace() async throws {
        let image = makeTestImage(size: CGSize(width: 200, height: 200))
        let result = try await service.render(
            image: image, faces: [makeFace(isMasked: false, intensity: 0.5)]
        )

        #expect(result.size == image.size)
    }

    // MARK: - Per-style smoke tests

    @Test("blurredGlass style does not throw")
    func renderBlurredGlass() async throws {
        let image = makeTestImage(size: CGSize(width: 300, height: 300))
        let result = try await service.render(
            image: image, faces: [makeFace(style: .blurredGlass)]
        )

        #expect(result.size == image.size)
    }

    @Test("pixelArt style does not throw")
    func renderPixelArt() async throws {
        let image = makeTestImage(size: CGSize(width: 300, height: 300))
        let result = try await service.render(
            image: image, faces: [makeFace(style: .pixelArt)]
        )

        #expect(result.size == image.size)
    }

    @Test("solidClean style does not throw")
    func renderSolidClean() async throws {
        let image = makeTestImage(size: CGSize(width: 300, height: 300))
        let result = try await service.render(
            image: image, faces: [makeFace(style: .solidClean)]
        )

        #expect(result.size == image.size)
    }

    // MARK: - sizeMultiplier

    @Test("sizeMultiplier > 1 expands bounding box without throwing")
    func renderExpandedBox() async throws {
        let image = makeTestImage(size: CGSize(width: 300, height: 300))
        let result = try await service.render(
            image: image, faces: [makeFace(sizeMultiplier: 2.0)]
        )

        #expect(result.size == image.size)
    }

    @Test("sizeMultiplier < 1 shrinks bounding box without throwing")
    func renderShrunkenBox() async throws {
        let image = makeTestImage(size: CGSize(width: 300, height: 300))
        let result = try await service.render(
            image: image, faces: [makeFace(sizeMultiplier: 0.5)]
        )

        #expect(result.size == image.size)
    }

    // MARK: - Intensity extremes

    @Test("intensity of 0.0 (minimum) does not throw")
    func renderIntensityMin() async throws {
        let image = makeTestImage(size: CGSize(width: 200, height: 200))
        let result = try await service.render(
            image: image, faces: [makeFace(style: .blurredGlass, intensity: 0.0)]
        )

        #expect(result.size == image.size)
    }

    @Test("intensity of 1.0 (maximum) does not throw")
    func renderIntensityMax() async throws {
        let image = makeTestImage(size: CGSize(width: 200, height: 200))
        let result = try await service.render(
            image: image, faces: [makeFace(style: .blurredGlass, intensity: 1.0)]
        )

        #expect(result.size == image.size)
    }

    // MARK: - Multi-face rendering

    @Test("Rendering multiple faces with different styles produces correct dimensions")
    func renderMultipleFaces() async throws {
        let image = makeTestImage(size: CGSize(width: 400, height: 400))
        let faces: [FaceBox] = [
            makeFace(x: 0.05, y: 0.05, width: 0.20, height: 0.20, style: .blurredGlass),
            makeFace(x: 0.50, y: 0.50, width: 0.20, height: 0.20, style: .pixelArt),
            makeFace(x: 0.30, y: 0.30, width: 0.15, height: 0.15, style: .solidClean),
        ]

        let result = try await service.render(
            image: image, faces: faces
        )

        #expect(result.size == image.size)
    }

    @Test("Mixed masked/unmasked faces render without throwing")
    func renderMixedMaskedState() async throws {
        let image = makeTestImage(size: CGSize(width: 300, height: 300))
        let faces: [FaceBox] = [
            makeFace(x: 0.1, y: 0.1, style: .solidClean, isMasked: true),
            makeFace(x: 0.6, y: 0.6, style: .blurredGlass, isMasked: false),
        ]

        let result = try await service.render(
            image: image, faces: faces
        )

        #expect(result.size == image.size)
    }

    // MARK: - Edge-case rects

    @Test("Face rect at the image boundary does not throw")
    func renderBoundaryRect() async throws {
        // A face that starts at (0, 0) and fills the entire normalized space
        let image = makeTestImage(size: CGSize(width: 200, height: 200))
        let face = makeFace(x: 0.0, y: 0.0, width: 1.0, height: 1.0)

        let result = try await service.render(
            image: image, faces: [face]
        )

        #expect(result.size == image.size)
    }
}
