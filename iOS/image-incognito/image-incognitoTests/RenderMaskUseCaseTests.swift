//
//  RenderMaskUseCaseTests.swift
//  image-incognitoTests
//
//  Unit tests for RenderMaskUseCase.
//  Verifies that all rendering parameters are forwarded to the repository
//  unchanged and that errors/results are passed through correctly.
//

import Testing
import UIKit
@testable import image_incognito

@Suite("RenderMaskUseCase")
struct RenderMaskUseCaseTests {

    // MARK: - Mocks

    private final class CapturingRenderRepository: MaskRenderingRepositoryProtocol {
        private(set) var capturedFaces: [FaceBox]?
        private(set) var capturedColor: UIColor?
        let imageToReturn: UIImage

        init(imageToReturn: UIImage = makeTestImage()) {
            self.imageToReturn = imageToReturn
        }

        func render(
            image: UIImage,
            faces: [FaceBox],
            solidCleanColor: UIColor
        ) async throws -> UIImage {
            capturedFaces = faces
            capturedColor = solidCleanColor
            return imageToReturn
        }
    }

    private struct ThrowingRenderRepository: MaskRenderingRepositoryProtocol {
        let error: Error

        func render(
            image: UIImage, faces: [FaceBox], solidCleanColor: UIColor
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
            image: makeTestImage(), faces: [],
            solidCleanColor: .white
        )

        #expect(result === expected)
    }

    @Test("execute forwards all parameters to the repository unchanged")
    func executeForwardsAllParameters() async throws {
        let face = FaceBox(rect: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.3))
        let mock = CapturingRenderRepository()
        let useCase = RenderMaskUseCase(repository: mock)

        _ = try await useCase.execute(
            image: makeTestImage(),
            faces: [face],
            solidCleanColor: .systemBlue
        )

        #expect(mock.capturedFaces?.first?.id == face.id)
        #expect(mock.capturedColor == .systemBlue)
    }

    @Test("execute forwards multiple faces to the repository")
    func executeForwardsMultipleFaces() async throws {
        let faces = [
            FaceBox(rect: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2)),
            FaceBox(rect: CGRect(x: 0.6, y: 0.1, width: 0.2, height: 0.2)),
            FaceBox(rect: CGRect(x: 0.3, y: 0.5, width: 0.2, height: 0.2))
        ]
        let mock = CapturingRenderRepository()
        let useCase = RenderMaskUseCase(repository: mock)

        _ = try await useCase.execute(
            image: makeTestImage(), faces: faces,
            solidCleanColor: .white
        )

        #expect(mock.capturedFaces?.count == 3)
    }

    @Test("execute propagates errors thrown by the repository")
    func executePropagatesErrors() async throws {
        struct RenderError: Error {}
        let useCase = RenderMaskUseCase(repository: ThrowingRenderRepository(error: RenderError()))

        await #expect(throws: RenderError.self) {
            try await useCase.execute(
                image: makeTestImage(), faces: [],
                solidCleanColor: .white
            )
        }
    }
}
