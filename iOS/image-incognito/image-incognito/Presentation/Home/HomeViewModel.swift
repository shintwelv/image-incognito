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

    // MARK: - Selected images (passed to AI Editor)

    var selectedImages: [UIImage] = []

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

    /// Called once PHPicker returns images (up to 5).
    func didSelectImages(_ images: [UIImage]) {
        selectedImages = images
    }
}
