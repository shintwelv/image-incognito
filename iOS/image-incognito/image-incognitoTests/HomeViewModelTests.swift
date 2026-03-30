//
//  HomeViewModelTests.swift
//  image-incognitoTests
//
//  Unit tests for HomeViewModel navigation state and image selection.
//

import Testing
import UIKit
@testable import image_incognito

@Suite("HomeViewModel")
struct HomeViewModelTests {

    @Test("Initial state: all flags false, no selected image, no recent items")
    func initialState() {
        let vm = HomeViewModel()

        #expect(vm.isShowingPhotoPicker == false)
        #expect(vm.isShowingCamera == false)
        #expect(vm.isShowingSettings == false)
        #expect(vm.selectedImage == nil)
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

    @Test("didSelectImage stores the provided image")
    func didSelectImage() {
        let vm = HomeViewModel()
        let image = makeTestImage()
        vm.didSelectImage(image)

        #expect(vm.selectedImage === image)
    }

    @Test("didSelectImage replaces a previously selected image")
    func replaceSelectedImage() {
        let vm = HomeViewModel()
        let first = makeTestImage(color: .red)
        let second = makeTestImage(color: .green)

        vm.didSelectImage(first)
        #expect(vm.selectedImage === first)

        vm.didSelectImage(second)
        #expect(vm.selectedImage === second)
    }
}
