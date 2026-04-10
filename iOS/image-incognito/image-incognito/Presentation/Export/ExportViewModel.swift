//
//  ExportViewModel.swift
//  image-incognito
//
//  Presentation – Export Screen ViewModel
//  Manages save-to-Photos, system share sheet, and metadata settings.
//

import SwiftUI
import Observation

@Observable
final class ExportViewModel {

    // MARK: - Input

    /// All final masked images passed from the AI Editor.
    let maskedImages: [UIImage]

    /// The image currently shown in the preview pager.
    var currentPreviewIndex: Int = 0

    var currentImage: UIImage { maskedImages[currentPreviewIndex] }

    // MARK: - Settings

    var settings = ExportSettings()

    // MARK: - Save state

    var isSaving: Bool = false
    var showSaveToast: Bool = false
    var saveToastMessage: String = "저장 완료"
    var saveError: String? = nil

    // MARK: - Share state

    var isShowingShareSheet: Bool = false
    /// Settings-applied image to hand off to the share sheet.
    private(set) var imageToShare: UIImage?

    // MARK: - Dependencies

    private let processingService: ExportImageProcessingService
    private let photoService: PhotoLibraryService

    // MARK: - Init

    init(
        maskedImages: [UIImage],
        processingService: ExportImageProcessingService = ExportImageProcessingService(),
        photoService: PhotoLibraryService = PhotoLibraryService()
    ) {
        self.maskedImages = maskedImages
        self.processingService = processingService
        self.photoService = photoService
    }

    // MARK: - Intent: Save to Photos

    func saveToPhotos() async {
        guard !isSaving else { return }
        isSaving = true

        var savedCount = 0
        var lastError: Error?

        for image in maskedImages {
            do {
                let processed = await processingService.process(image, settings: settings)
                try await photoService.saveImageToAlbum(processed)
                savedCount += 1
            } catch {
                lastError = error
            }
        }

        await MainActor.run {
            isSaving = false
            if savedCount > 0 {
                AppHaptics.success()
                saveToastMessage = maskedImages.count > 1 ? "\(savedCount)장 저장 완료" : "저장 완료"
                withAnimation(AppAnimation.standard) {
                    showSaveToast = true
                }
            }
            if let error = lastError {
                saveError = error.localizedDescription
            }
        }
    }

    // MARK: - Intent: Share

    func shareImageTapped() {
        AppHaptics.light()
        let imageToProcess = maskedImages[currentPreviewIndex]
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            let processed = await self.processingService.process(imageToProcess, settings: self.settings)
            await MainActor.run {
                self.imageToShare = processed
                self.isShowingShareSheet = true
            }
        }
    }

    // MARK: - Error dismiss

    func dismissError() {
        saveError = nil
    }
}
