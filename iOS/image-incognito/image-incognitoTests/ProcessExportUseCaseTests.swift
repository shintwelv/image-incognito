//
//  ProcessExportUseCaseTests.swift
//  image-incognitoTests
//
//  Unit tests for ProcessExportUseCase.
//  Verifies that ExportSettings are forwarded to the repository unchanged
//  and that the processed image is returned. The use case is non-throwing
//  by design — tests confirm no `throws` annotation is present.
//

import Testing
import UIKit
@testable import image_incognito

@Suite("ProcessExportUseCase")
struct ProcessExportUseCaseTests {

    // MARK: - Mock

    private final class CapturingExportRepository: ExportProcessingRepositoryProtocol {
        private(set) var capturedSettings: ExportSettings?
        private(set) var capturedImage: UIImage?
        let imageToReturn: UIImage

        init(imageToReturn: UIImage = makeTestImage()) {
            self.imageToReturn = imageToReturn
        }

        func process(_ image: UIImage, settings: ExportSettings) async -> UIImage {
            capturedImage = image
            capturedSettings = settings
            return imageToReturn
        }
    }

    // MARK: - Tests

    @Test("execute returns the image provided by the repository")
    func executeReturnsProcessedImage() async {
        let expected = makeTestImage(color: .systemGreen)
        let mock = CapturingExportRepository(imageToReturn: expected)
        let useCase = ProcessExportUseCase(repository: mock)

        let result = await useCase.execute(image: makeTestImage(), settings: ExportSettings())

        #expect(result === expected)
    }

    @Test("execute passes the source image to the repository unchanged")
    func executeForwardsSourceImage() async {
        let source = makeTestImage(size: CGSize(width: 300, height: 400))
        let mock = CapturingExportRepository()
        let useCase = ProcessExportUseCase(repository: mock)

        _ = await useCase.execute(image: source, settings: ExportSettings())

        #expect(mock.capturedImage === source)
    }

    @Test("execute passes ExportSettings to the repository unchanged")
    func executeForwardsSettings() async {
        let settings = ExportSettings(
            removeLocation: false,
            removeExif: true,
            keepOriginalResolution: false
        )
        let mock = CapturingExportRepository()
        let useCase = ProcessExportUseCase(repository: mock)

        _ = await useCase.execute(image: makeTestImage(), settings: settings)

        #expect(mock.capturedSettings?.removeLocation == false)
        #expect(mock.capturedSettings?.removeExif == true)
        #expect(mock.capturedSettings?.keepOriginalResolution == false)
    }

    @Test("execute passes default ExportSettings correctly")
    func executeForwardsDefaultSettings() async {
        let mock = CapturingExportRepository()
        let useCase = ProcessExportUseCase(repository: mock)

        _ = await useCase.execute(image: makeTestImage(), settings: ExportSettings())

        #expect(mock.capturedSettings?.removeLocation == true)
        #expect(mock.capturedSettings?.removeExif == true)
        #expect(mock.capturedSettings?.keepOriginalResolution == true)
    }

    @Test("execute is non-throwing by design")
    func executeIsNonThrowing() async {
        // ProcessExportUseCase.execute is declared `async` (not `async throws`).
        // This test serves as a compile-time contract check — if the signature
        // gains `throws` accidentally, this test would fail to compile without try.
        let useCase = ProcessExportUseCase(repository: CapturingExportRepository())
        let result = await useCase.execute(image: makeTestImage(), settings: ExportSettings())
        #expect(result != nil)
    }
}
