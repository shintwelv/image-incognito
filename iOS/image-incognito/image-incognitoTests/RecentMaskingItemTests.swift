//
//  RecentMaskingItemTests.swift
//  image-incognitoTests
//
//  Unit tests for the RecentMaskingItem domain entity.
//

import Testing
import Foundation
@testable import image_incognito

@Suite("RecentMaskingItem")
struct RecentMaskingItemTests {

    @Test("Init stores all provided values")
    func storesValues() {
        let image = makeTestImage()
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_000_000)
        let item = RecentMaskingItem(id: id, thumbnail: image, date: date, maskedFaceCount: 3)

        #expect(item.id == id)
        #expect(item.thumbnail === image)
        #expect(item.date == date)
        #expect(item.maskedFaceCount == 3)
    }

    @Test("Default id is unique across instances")
    func uniqueIds() {
        let image = makeTestImage()
        let a = RecentMaskingItem(thumbnail: image, maskedFaceCount: 1)
        let b = RecentMaskingItem(thumbnail: image, maskedFaceCount: 1)

        #expect(a.id != b.id)
    }

    @Test("Default date is approximately now")
    func defaultDateIsNow() {
        let before = Date()
        let item = RecentMaskingItem(thumbnail: makeTestImage(), maskedFaceCount: 0)
        let after = Date()

        #expect(item.date >= before)
        #expect(item.date <= after)
    }

    @Test("maskedFaceCount of zero is valid")
    func zeroFaceCount() {
        let item = RecentMaskingItem(thumbnail: makeTestImage(), maskedFaceCount: 0)
        #expect(item.maskedFaceCount == 0)
    }
}
