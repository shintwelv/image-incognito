//
//  PhotoLibraryServiceTests.swift
//  image-incognitoTests
//
//  Unit tests for PhotoLibraryService and PhotoLibraryError descriptions.
//

import Testing
import Foundation
@testable import image_incognito

@Suite("PhotoLibraryServiceTests")
@MainActor
struct PhotoLibraryServiceTests {

    @Test("PhotoLibraryError errorDescription returns correct localized strings")
    func testPhotoLibraryErrorDescriptions() {
        let unauthorizedErr = PhotoLibraryError.unauthorized
        let failedToSaveErr = PhotoLibraryError.failedToSave
        let albumErr = PhotoLibraryError.failedToGetOrCreateAlbum

        #expect(unauthorizedErr.errorDescription != nil)
        #expect(failedToSaveErr.errorDescription != nil)
        #expect(albumErr.errorDescription != nil)
    }

    @Test("PhotoLibraryService initializes correctly")
    func testServiceInit() {
        let service = PhotoLibraryService()
        #expect(service.saveImageToAlbum != nil)
    }
}
