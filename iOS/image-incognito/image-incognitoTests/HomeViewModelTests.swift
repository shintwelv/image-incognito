//
//  HomeViewModelTests.swift
//  image-incognitoTests
//
//  Unit tests for HomeViewModel navigation state and image selection.
//

import Testing
import UIKit
@testable import image_incognito

@MainActor
@Suite("HomeViewModel")
struct HomeViewModelTests {

    @Test("Initial state: all flags false, no selected images, no recent items")
    func initialState() {
        let vm = HomeViewModel()

        #expect(vm.isShowingPhotoPicker == false)
        #expect(vm.isShowingCamera == false)
        #expect(vm.isShowingSettings == false)
        #expect(vm.selectedImages.isEmpty)
        #expect(vm.recentItems.isEmpty)
    }

    @Test("selectPhotoTapped sets isShowingPhotoPicker to true")
    func selectPhotoTapped() {
        let vm = HomeViewModel()
        vm.selectPhotoTapped()

        #expect(vm.isShowingPhotoPicker == true)
    }

    @Test("cameraTapped sets isShowingCamera to true")
    func cameraTapped() {
        let vm = HomeViewModel()
        vm.cameraTapped()

        #expect(vm.isShowingCamera == true)
    }

    @Test("settingsTapped sets isShowingSettings to true")
    func settingsTapped() {
        let vm = HomeViewModel()
        vm.settingsTapped()

        #expect(vm.isShowingSettings == true)
    }

    @Test("didSelectImages stores the provided images")
    func didSelectImages() {
        let vm = HomeViewModel()
        let image = makeTestImage()
        vm.didSelectImages([image])

        #expect(vm.selectedImages.first === image)
    }

    @Test("didSelectImages replaces previously selected images")
    func replaceSelectedImages() {
        let vm = HomeViewModel()
        let first = makeTestImage(color: .red)
        let second = makeTestImage(color: .green)

        vm.didSelectImages([first])
        #expect(vm.selectedImages.first === first)

        vm.didSelectImages([second])
        #expect(vm.selectedImages.first === second)
    }
}
