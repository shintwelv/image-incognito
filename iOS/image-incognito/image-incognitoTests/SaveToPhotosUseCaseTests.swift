//
//  SaveToPhotosUseCaseTests.swift
//  image-incognitoTests
//
//  Unit tests for SaveToPhotosUseCase.
//  Verifies successful delegation and that PhotoLibraryError.unauthorized
//  (and other errors) are propagated to the caller.
//

import Testing
import UIKit
@testable import image_incognito

@Suite("SaveToPhotosUseCase")
struct SaveToPhotosUseCaseTests {

    // MARK: - Mocks

    private final class CapturingSaveRepository: PhotoLibraryRepositoryProtocol {
        private(set) var savedImages: [UIImage] = []

        func saveImageToAlbum(_ image: UIImage) async throws {
            savedImages.append(image)
        }
    }

    private struct ThrowingPhotoLibraryRepository: PhotoLibraryRepositoryProtocol {
        let error: Error

        func saveImageToAlbum(_ image: UIImage) async throws {
            throw error
        }
    }

    // MARK: - Tests

    @Test("execute delegates to the repository without throwing")
    func executeSucceeds() async throws {
        let mock = CapturingSaveRepository()
        let useCase = SaveToPhotosUseCase(repository: mock)

        try await useCase.execute(image: makeTestImage())

        #expect(mock.savedImages.count == 1)
    }

    @Test("execute passes the correct image to the repository")
    func executePassesImage() async throws {
        let source = makeTestImage(size: CGSize(width: 300, height: 400))
        let mock = CapturingSaveRepository()
        let useCase = SaveToPhotosUseCase(repository: mock)

        try await useCase.execute(image: source)

        #expect(mock.savedImages.first === source)
    }

    @Test("execute propagates PhotoLibraryError.unauthorized")
    func executePropagatesUnauthorized() async throws {
        let useCase = SaveToPhotosUseCase(
            repository: ThrowingPhotoLibraryRepository(error: PhotoLibraryError.unauthorized)
        )

        await #expect(throws: PhotoLibraryError.self) {
            try await useCase.execute(image: makeTestImage())
        }
    }

    @Test("execute propagates any error thrown by the repository")
    func executePropagatesGenericError() async throws {
        struct SaveError: Error {}
        let useCase = SaveToPhotosUseCase(
            repository: ThrowingPhotoLibraryRepository(error: SaveError())
        )

        await #expect(throws: SaveError.self) {
            try await useCase.execute(image: makeTestImage())
        }
    }
}
