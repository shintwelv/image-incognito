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

    // MARK: - Init

    init(maskedImage: UIImage) {
        self.maskedImage = maskedImage
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
                    saveError = "사진 접근 권한이 없습니다. 설정 앱에서 권한을 허용해주세요."
                }
                return
            }

            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: self.maskedImage)
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
        isShowingShareSheet = true
    }

    // MARK: - Error dismiss

    func dismissError() {
        saveError = nil
    }
}
