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
}
