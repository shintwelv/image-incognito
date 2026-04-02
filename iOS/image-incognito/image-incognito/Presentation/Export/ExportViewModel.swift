//
//  ExportViewModel.swift
//  image-incognito
//
//  Presentation – Export Screen ViewModel
//  Manages save-to-Photos, system share sheet, and metadata settings.
//

import SwiftUI
import Photos
import Observation

@Observable
final class ExportViewModel {

    // MARK: - Input

    /// The final masked image passed from the AI Editor.
    let maskedImage: UIImage

    // MARK: - Settings

    var settings = ExportSettings()

    // MARK: - Save state

    var isSaving: Bool = false
    var showSaveToast: Bool = false
    var saveError: String? = nil

    // MARK: - Share state

    var isShowingShareSheet: Bool = false
    /// Settings-applied image to hand off to the share sheet.
    private(set) var imageToShare: UIImage?

    // MARK: - Dependencies

    private let processingService: ExportImageProcessingService

    // MARK: - Init

    init(
        maskedImage: UIImage,
        processingService: ExportImageProcessingService = ExportImageProcessingService()
    ) {
        self.maskedImage = maskedImage
        self.processingService = processingService
    }

    // MARK: - Intent: Save to Photos

    func saveToPhotos() async {
        guard !isSaving else { return }
        isSaving = true

        do {
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited else {
                await MainActor.run {
                    isSaving = false
                    saveError = String(localized: "사진 접근 권한이 없습니다. 설정 앱에서 권한을 허용해주세요.")
                }
                return
            }

            let processed = await processingService.process(maskedImage, settings: settings)

            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: processed)
            }

            await MainActor.run {
                isSaving = false
                AppHaptics.success()
                withAnimation(AppAnimation.standard) {
                    showSaveToast = true
                }
            }
        } catch {
            await MainActor.run {
                isSaving = false
                saveError = error.localizedDescription
            }
        }
    }

    // MARK: - Intent: Share

    func shareImageTapped() {
        AppHaptics.light()
        Task.detached(priority: .background) { [weak self] in
            guard let self = self else { return }
            let processed = await self.processingService.process(maskedImage, settings: settings)
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
