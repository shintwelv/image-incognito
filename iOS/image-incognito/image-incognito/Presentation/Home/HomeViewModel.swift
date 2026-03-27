//
//  HomeViewModel.swift
//  image-incognito
//
//  Presentation – Home Screen ViewModel
//  Uses iOS 17 Observation framework (@Observable).
//

import SwiftUI
import Observation

@Observable
final class HomeViewModel {

    // MARK: - Navigation / Sheet state

    var isShowingPhotoPicker = false
    var isShowingCamera = false
    var isShowingSettings = false

    // MARK: - Selected image (passed to AI Editor)

    var selectedImage: UIImage? = nil

    // MARK: - Recent items

    var recentItems: [RecentMaskingItem] = []

    // MARK: - Intent

    func selectPhotoTapped() {
        AppHaptics.medium()
        isShowingPhotoPicker = true
    }

    func cameraTapped() {
        AppHaptics.medium()
        isShowingCamera = true
    }

    func settingsTapped() {
        AppHaptics.light()
        isShowingSettings = true
    }

    /// Called once PHPicker returns an image.
    func didSelectImage(_ image: UIImage) {
        selectedImage = image
        // Navigate to AI Editor (selectedImage being non-nil triggers navigation)
    }
}
