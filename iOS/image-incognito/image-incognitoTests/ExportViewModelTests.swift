//
//  ExportViewModelTests.swift
//  image-incognitoTests
//
//  Unit tests for ExportViewModel: initial state, share sheet trigger,
//  and error management. (saveToPhotos requires device photo-library access
//  and is not covered here.)
//

import Testing
import UIKit
@testable import image_incognito

@MainActor
@Suite("ExportViewModel")
struct ExportViewModelTests {

    private final class CapturingExportRepository: ExportProcessingRepositoryProtocol {
        private(set) var capturedImages: [UIImage] = []
        private(set) var capturedSettings: [ExportSettings] = []
        private let imagesToReturn: [UIImage]

        init(imagesToReturn: [UIImage]) {
            self.imagesToReturn = imagesToReturn
        }

        func process(_ image: UIImage, settings: ExportSettings) async -> UIImage {
            capturedImages.append(image)
            capturedSettings.append(settings)
            return imagesToReturn[capturedImages.count - 1]
        }
    }

    private final class CapturingSaveRepository: PhotoLibraryRepositoryProtocol {
        private(set) var savedImages: [UIImage] = []
        private let error: Error?

        init(error: Error? = nil) {
            self.error = error
        }

        func saveImageToAlbum(_ image: UIImage) async throws {
            if let error {
                throw error
            }
            savedImages.append(image)
        }
    }

    private struct SaveFailure: LocalizedError {
        var errorDescription: String? { "save failed" }
    }

    @Test("Initial state is clean")
    func initialState() {
        let vm = ExportViewModel(maskedImages: [makeTestImage()])

        #expect(vm.isSaving == false)
        #expect(vm.showSaveToast == false)
        #expect(vm.saveError == nil)
        #expect(vm.isShowingShareSheet == false)
    }

    @Test("maskedImages is stored from init")
    func maskedImagesStored() {
        let image = makeTestImage()
        let vm = ExportViewModel(maskedImages: [image])

        #expect(vm.maskedImages.first === image)
    }

    @Test("Default ExportSettings have all options enabled")
    func defaultExportSettings() {
        let vm = ExportViewModel(maskedImages: [makeTestImage()])

        #expect(vm.settings.removeLocation == true)
        #expect(vm.settings.removeExif == true)
        #expect(vm.settings.keepOriginalResolution == true)
    }

    @Test("shareImageTapped sets isShowingShareSheet to true")
    func shareImageTapped() async {
        let vm = ExportViewModel(maskedImages: [makeTestImage()])
        vm.shareImageTapped()

        await confirmation("should show share sheet") { confirm in
            let start = Date()

            while !vm.isShowingShareSheet, Date().timeIntervalSince(start) < 1 {
                await Task.yield()
            }

            if vm.isShowingShareSheet {
                confirm()
            }
        }
    }

    @Test("dismissError clears saveError")
    func dismissError() {
        let vm = ExportViewModel(maskedImages: [makeTestImage()])
        vm.saveError = "Something went wrong"
        vm.dismissError()

        #expect(vm.saveError == nil)
    }

    @Test("dismissError is a no-op when saveError is already nil")
    func dismissErrorWhenAlreadyNil() {
        let vm = ExportViewModel(maskedImages: [makeTestImage()])
        vm.dismissError()

        #expect(vm.saveError == nil)
    }

    @Test("saveError can be set and cleared independently")
    func saveErrorLifecycle() {
        let vm = ExportViewModel(maskedImages: [makeTestImage()])

        vm.saveError = "First error"
        #expect(vm.saveError == "First error")

        vm.saveError = "Second error"
        #expect(vm.saveError == "Second error")

        vm.dismissError()
        #expect(vm.saveError == nil)
    }

    @Test("settings can be mutated after init")
    func settingsMutation() {
        let vm = ExportViewModel(maskedImages: [makeTestImage()])
        vm.settings.removeLocation = false
        vm.settings.removeExif = false

        #expect(vm.settings.removeLocation == false)
        #expect(vm.settings.removeExif == false)
        #expect(vm.settings.keepOriginalResolution == true)
    }

    @Test("saveToPhotos saves every processed image and shows a success toast")
    func saveToPhotosSuccess() async {
        let sourceImages = [
            makeTestImage(size: CGSize(width: 100, height: 100), color: .systemBlue),
            makeTestImage(size: CGSize(width: 120, height: 80), color: .systemPink),
        ]
        let processedImages = [
            makeTestImage(size: CGSize(width: 100, height: 100), color: .systemGreen),
            makeTestImage(size: CGSize(width: 120, height: 80), color: .systemOrange),
        ]
        let exportRepository = CapturingExportRepository(imagesToReturn: processedImages)
        let saveRepository = CapturingSaveRepository()
        let vm = ExportViewModel(
            maskedImages: sourceImages,
            processExportUseCase: ProcessExportUseCase(repository: exportRepository),
            saveToPhotosUseCase: SaveToPhotosUseCase(repository: saveRepository)
        )

        await vm.saveToPhotos()

        #expect(vm.isSaving == false)
        #expect(vm.showSaveToast == true)
        #expect(vm.saveToastMessage == "2장 저장 완료")
        #expect(vm.saveError == nil)
        #expect(exportRepository.capturedImages.count == 2)
        #expect(saveRepository.savedImages.count == 2)
        #expect(saveRepository.savedImages[0] === processedImages[0])
        #expect(saveRepository.savedImages[1] === processedImages[1])
    }

    @Test("saveToPhotos surfaces the last save error when saving fails")
    func saveToPhotosFailure() async {
        let processedImage = makeTestImage(size: CGSize(width: 100, height: 100), color: .systemGreen)
        let exportRepository = CapturingExportRepository(imagesToReturn: [processedImage])
        let saveRepository = CapturingSaveRepository(error: SaveFailure())
        let vm = ExportViewModel(
            maskedImages: [makeTestImage()],
            processExportUseCase: ProcessExportUseCase(repository: exportRepository),
            saveToPhotosUseCase: SaveToPhotosUseCase(repository: saveRepository)
        )

        await vm.saveToPhotos()

        #expect(vm.isSaving == false)
        #expect(vm.showSaveToast == false)
        #expect(vm.saveError == "save failed")
        #expect(saveRepository.savedImages.isEmpty)
    }
}
