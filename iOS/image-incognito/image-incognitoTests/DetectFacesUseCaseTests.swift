//
//  DetectFacesUseCaseTests.swift
//  image-incognitoTests
//
//  Unit tests for DetectFacesUseCase.
//  Verifies delegation to the repository and that the use-case boundary does
//  not transform the returned FaceBox coordinates (the Vision coordinate flip
//  happens inside FaceDetectionService, not here).
//

import Testing
import UIKit
@testable import image_incognito

@Suite("DetectFacesUseCase")
struct DetectFacesUseCaseTests {

    // MARK: - Mocks

    private struct MockFaceDetectionRepository: FaceDetectionRepositoryProtocol {
        let facesToReturn: [FaceBox]

        func detectFaces(in image: UIImage) async throws -> [FaceBox] {
            facesToReturn
        }
    }

    private struct ThrowingFaceDetectionRepository: FaceDetectionRepositoryProtocol {
        let error: Error

        func detectFaces(in image: UIImage) async throws -> [FaceBox] {
            throw error
        }
    }

    // MARK: - Tests

    @Test("execute returns the faces provided by the repository")
    func executeReturnsFaces() async throws {
        let expected = [
            FaceBox(rect: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.3)),
            FaceBox(rect: CGRect(x: 0.6, y: 0.1, width: 0.25, height: 0.25))
        ]
        let useCase = DetectFacesUseCase(repository: MockFaceDetectionRepository(facesToReturn: expected))

        let result = try await useCase.execute(image: makeTestImage())

        #expect(result.count == 2)
        #expect(result[0].rect == expected[0].rect)
        #expect(result[1].rect == expected[1].rect)
    }

    @Test("execute does not transform coordinates at the use-case boundary")
    func executePassesThroughCoordinates() async throws {
        // The Vision bottom-left → UIKit top-left flip happens inside
        // FaceDetectionService. The use case must not apply any further transform.
        let knownRect = CGRect(x: 0.2, y: 0.45, width: 0.4, height: 0.35)
        let useCase = DetectFacesUseCase(
            repository: MockFaceDetectionRepository(facesToReturn: [FaceBox(rect: knownRect)])
        )

        let result = try await useCase.execute(image: makeTestImage())

        #expect(result[0].rect == knownRect)
    }

    @Test("execute returns an empty array when no faces are detected")
    func executeReturnsEmptyWhenNoFaces() async throws {
        let useCase = DetectFacesUseCase(repository: MockFaceDetectionRepository(facesToReturn: []))

        let result = try await useCase.execute(image: makeTestImage())

        #expect(result.isEmpty)
    }

    @Test("execute propagates errors thrown by the repository")
    func executePropagatesErrors() async throws {
        struct DetectionError: Error {}
        let useCase = DetectFacesUseCase(repository: ThrowingFaceDetectionRepository(error: DetectionError()))

        await #expect(throws: DetectionError.self) {
            try await useCase.execute(image: makeTestImage())
        }
    }

    @Test("execute preserves FaceBox isMasked and style from the repository")
    func executePreservesFaceBoxProperties() async throws {
        let face = FaceBox(
            rect: CGRect(x: 0.3, y: 0.3, width: 0.2, height: 0.2),
            isMasked: false,
            style: .pixelArt
        )
        let useCase = DetectFacesUseCase(
            repository: MockFaceDetectionRepository(facesToReturn: [face])
        )

        let result = try await useCase.execute(image: makeTestImage())

        #expect(result[0].isMasked == false)
        #expect(result[0].style == .pixelArt)
    }
}
