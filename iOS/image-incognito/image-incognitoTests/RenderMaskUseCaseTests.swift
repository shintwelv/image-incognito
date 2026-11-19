//
//  RenderMaskUseCaseTests.swift
//  image-incognitoTests
//
//  Unit tests for RenderMaskUseCase.
//  Verifies that all rendering parameters are forwarded to the repository
//  unchanged, that faces map to detected-face regions, and that errors/results
//  are passed through correctly.
//

import Testing
import UIKit
@testable import image_incognito

@MainActor
@Suite("RenderMaskUseCase")
struct RenderMaskUseCaseTests {

    // MARK: - Mocks

    private final class CapturingRenderRepository: MaskRenderingRepositoryProtocol {
        private(set) var capturedRegions: [MaskRegion]?
        private(set) var capturedColor: UIColor?
        let imageToReturn: UIImage

        init(imageToReturn: UIImage = makeTestImage()) {
            self.imageToReturn = imageToReturn
        }

        func render(
            image: UIImage,
            regions: [MaskRegion],
            solidCleanColor: UIColor
        ) async throws -> UIImage {
            capturedRegions = regions
            capturedColor = solidCleanColor
            return imageToReturn
        }
    }

    private struct ThrowingRenderRepository: MaskRenderingRepositoryProtocol {
        let error: Error

        func render(
            image: UIImage, regions: [MaskRegion], solidCleanColor: UIColor
        ) async throws -> UIImage {
            throw error
        }
    }

    // MARK: - Tests

    @Test("execute returns the image provided by the repository")
    func executeReturnsRenderedImage() async throws {
        let expected = makeTestImage(color: .systemRed)
        let mock = CapturingRenderRepository(imageToReturn: expected)
        let useCase = RenderMaskUseCase(repository: mock)

        let result = try await useCase.execute(
            image: makeTestImage(), regions: [],
            solidCleanColor: .white
        )

        #expect(result === expected)
    }

    @Test("execute forwards all region parameters to the repository unchanged")
    func executeForwardsAllParameters() async throws {
        let region = MaskRegion(
            source: .manual,
            shape: .rectangle,
            rect: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.3)
        )
        let mock = CapturingRenderRepository()
        let useCase = RenderMaskUseCase(repository: mock)

        _ = try await useCase.execute(
            image: makeTestImage(),
            regions: [region],
            solidCleanColor: .systemBlue
        )

        #expect(mock.capturedRegions?.first?.id == region.id)
        #expect(mock.capturedColor == .systemBlue)
    }

    @Test("execute forwards multiple regions to the repository")
    func executeForwardsMultipleRegions() async throws {
        let regions = [
            MaskRegion(source: .manual, shape: .rectangle, rect: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2)),
            MaskRegion(source: .manual, shape: .circle, rect: CGRect(x: 0.6, y: 0.1, width: 0.2, height: 0.2)),
            MaskRegion(source: .detectedFace, shape: .ellipse, rect: CGRect(x: 0.3, y: 0.5, width: 0.2, height: 0.2))
        ]
        let mock = CapturingRenderRepository()
        let useCase = RenderMaskUseCase(repository: mock)

        _ = try await useCase.execute(
            image: makeTestImage(), regions: regions,
            solidCleanColor: .white
        )

        #expect(mock.capturedRegions?.count == 3)
    }

    @Test("faces overload maps each FaceBox to a detected-face ellipse region")
    func executeMapsFacesToRegions() async throws {
        let face = FaceBox(
            rect: CGRect(x: 0.2, y: 0.3, width: 0.2, height: 0.25),
            isMasked: false,
            style: .pixelArt,
            intensity: 0.4,
            sizeMultiplier: 1.7,
            selectedEmoji: "🐱"
        )
        let mock = CapturingRenderRepository()
        let useCase = RenderMaskUseCase(repository: mock)

        _ = try await useCase.execute(
            image: makeTestImage(),
            faces: [face],
            solidCleanColor: .white
        )

        let region = try #require(mock.capturedRegions?.first)
        #expect(mock.capturedRegions?.count == 1)
        #expect(region.id == face.id)
        #expect(region.source == .detectedFace)
        #expect(region.shape == .ellipse)
        #expect(rectsAreEqual(region.rect, face.rect))
        #expect(region.isIncluded == false)
        #expect(region.style == .pixelArt)
        #expect(region.intensity == 0.4)
        #expect(region.sizeMultiplier == 1.7)
        #expect(region.selectedEmoji == "🐱")
        #expect(region.linkedFaceID == face.id)
    }

    @Test("execute propagates errors thrown by the repository for regions")
    func executePropagatesRegionErrors() async throws {
        struct RenderError: Error {}
        let useCase = RenderMaskUseCase(repository: ThrowingRenderRepository(error: RenderError()))

        await #expect(throws: RenderError.self) {
            try await useCase.execute(
                image: makeTestImage(), regions: [],
                solidCleanColor: .white
            )
        }
    }

    @Test("execute propagates errors thrown by the repository for faces")
    func executePropagatesFaceErrors() async throws {
        struct RenderError: Error {}
        let useCase = RenderMaskUseCase(repository: ThrowingRenderRepository(error: RenderError()))
        let face = FaceBox(rect: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2))

        await #expect(throws: RenderError.self) {
            try await useCase.execute(
                image: makeTestImage(), faces: [face],
                solidCleanColor: .white
            )
        }
    }
}
