//
//  ExportViewModel.swift
//  image-incognito
//
//  Presentation – Export Screen ViewModel
//  Manages save-to-Photos, system share sheet, and metadata settings.
//

import SwiftUI
import Observation

@MainActor
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

    // MARK: - Use Cases

    private let processExportUseCase: ProcessExportUseCase
    private let saveToPhotosUseCase: SaveToPhotosUseCase

    // MARK: - Init

    init(
        maskedImages: [UIImage],
        processExportUseCase: ProcessExportUseCase = ProcessExportUseCase(repository: ExportImageProcessingService()),
        saveToPhotosUseCase: SaveToPhotosUseCase = SaveToPhotosUseCase(repository: PhotoLibraryService())
    ) {
        self.maskedImages = maskedImages
        self.processExportUseCase = processExportUseCase
        self.saveToPhotosUseCase = saveToPhotosUseCase
    }

    // MARK: - Intent: Save to Photos

    func saveToPhotos() async {
        guard !isSaving else { return }
        isSaving = true

        var savedCount = 0
        var lastError: Error?

        for image in maskedImages {
            do {
                let processed = await processExportUseCase.execute(image: image, settings: settings)
                try await saveToPhotosUseCase.execute(image: processed)
                savedCount += 1
            } catch {
                lastError = error
            }
        }

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

    // MARK: - Intent: Share

    func shareImageTapped() {
        AppHaptics.light()
        let imageToProcess = maskedImages[currentPreviewIndex]
        Task { [weak self] in
            guard let self else { return }
            let processed = await self.processExportUseCase.execute(image: imageToProcess, settings: self.settings)
            self.imageToShare = processed
            self.isShowingShareSheet = true
        }
    }

    // MARK: - Error dismiss

    func dismissError() {
        saveError = nil
    }
}
