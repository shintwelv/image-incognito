//
//  RecentMaskingItem.swift
//  image-incognito
//
//  Domain Entity – represents a recently processed (masked) image entry.
//  UIKit-free: thumbnail is stored as raw JPEG bytes so the Domain layer
//  has no framework dependency. Presentation layer converts to UIImage on use.
//

import Foundation

struct RecentMaskingItem: Identifiable {
    let id: UUID
    /// JPEG-encoded thumbnail of the masked result (blurred for privacy).
    let thumbnailData: Data
    let date: Date
    /// Number of faces that were masked.
    let maskedFaceCount: Int

    init(
        id: UUID = UUID(),
        thumbnailData: Data,
        date: Date = .now,
        maskedFaceCount: Int
    ) {
        self.id = id
        self.thumbnailData = thumbnailData
        self.date = date
        self.maskedFaceCount = maskedFaceCount
    }
}
