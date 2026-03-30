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

@Suite("ExportViewModel")
struct ExportViewModelTests {

    @Test("Initial state is clean")
    func initialState() {
        let vm = ExportViewModel(maskedImage: makeTestImage())

        #expect(vm.isSaving == false)
        #expect(vm.showSaveToast == false)
        #expect(vm.saveError == nil)
        #expect(vm.isShowingShareSheet == false)
    }

    @Test("maskedImage is stored from init")
    func maskedImageStored() {
        let image = makeTestImage()
        let vm = ExportViewModel(maskedImage: image)

        #expect(vm.maskedImage === image)
    }

    @Test("Default ExportSettings have all options enabled")
    func defaultExportSettings() {
        let vm = ExportViewModel(maskedImage: makeTestImage())

        #expect(vm.settings.removeLocation == true)
        #expect(vm.settings.removeExif == true)
        #expect(vm.settings.keepOriginalResolution == true)
    }

    @Test("shareImageTapped sets isShowingShareSheet to true")
    func shareImageTapped() {
        let vm = ExportViewModel(maskedImage: makeTestImage())
        vm.shareImageTapped()

        #expect(vm.isShowingShareSheet == true)
    }

    @Test("dismissError clears saveError")
    func dismissError() {
        let vm = ExportViewModel(maskedImage: makeTestImage())
        vm.saveError = "Something went wrong"
        vm.dismissError()

        #expect(vm.saveError == nil)
    }

    @Test("dismissError is a no-op when saveError is already nil")
    func dismissErrorWhenAlreadyNil() {
        let vm = ExportViewModel(maskedImage: makeTestImage())
        vm.dismissError()

        #expect(vm.saveError == nil)
    }

    @Test("saveError can be set and cleared independently")
    func saveErrorLifecycle() {
        let vm = ExportViewModel(maskedImage: makeTestImage())

        vm.saveError = "First error"
        #expect(vm.saveError == "First error")

        vm.saveError = "Second error"
        #expect(vm.saveError == "Second error")

        vm.dismissError()
        #expect(vm.saveError == nil)
    }

    @Test("settings can be mutated after init")
    func settingsMutation() {
        let vm = ExportViewModel(maskedImage: makeTestImage())
        vm.settings.removeLocation = false
        vm.settings.removeExif = false

        #expect(vm.settings.removeLocation == false)
        #expect(vm.settings.removeExif == false)
        #expect(vm.settings.keepOriginalResolution == true)
    }
}
