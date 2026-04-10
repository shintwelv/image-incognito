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

    // MARK: - Helpers

    private func makeThumbnailData() -> Data {
        makeTestImage().jpegData(compressionQuality: 0.8) ?? Data()
    }

    @Test("Init stores all provided values")
    func storesValues() {
        let data = makeThumbnailData()
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_000_000)
        let item = RecentMaskingItem(id: id, thumbnailData: data, date: date, maskedFaceCount: 3)

        #expect(item.id == id)
        #expect(item.thumbnailData == data)
        #expect(item.date == date)
        #expect(item.maskedFaceCount == 3)
    }

    @Test("Default id is unique across instances")
    func uniqueIds() {
        let data = makeThumbnailData()
        let a = RecentMaskingItem(thumbnailData: data, maskedFaceCount: 1)
        let b = RecentMaskingItem(thumbnailData: data, maskedFaceCount: 1)

        #expect(a.id != b.id)
    }

    @Test("Default date is approximately now")
    func defaultDateIsNow() {
        let before = Date()
        let item = RecentMaskingItem(thumbnailData: makeThumbnailData(), maskedFaceCount: 0)
        let after = Date()

        #expect(item.date >= before)
        #expect(item.date <= after)
    }

    @Test("maskedFaceCount of zero is valid")
    func zeroFaceCount() {
        let item = RecentMaskingItem(thumbnailData: makeThumbnailData(), maskedFaceCount: 0)
        #expect(item.maskedFaceCount == 0)
    }

    @Test("thumbnailImage returns a UIImage decoded from thumbnailData")
    func thumbnailImageDecodes() {
        let data = makeThumbnailData()
        let item = RecentMaskingItem(thumbnailData: data, maskedFaceCount: 1)

        #expect(item.thumbnailImage != nil)
    }

    @Test("thumbnailImage returns nil for invalid data")
    func thumbnailImageNilOnBadData() {
        let item = RecentMaskingItem(thumbnailData: Data(), maskedFaceCount: 0)
        #expect(item.thumbnailImage == nil)
    }
}
