//
//  RecentMaskingItem.swift
//  image-incognito
//
//  Domain Entity – represents a recently processed (masked) image entry.
//

import UIKit

struct RecentMaskingItem: Identifiable {
    let id: UUID
    /// Thumbnail of the masked result (stored blurred for privacy)
    let thumbnail: UIImage
    let date: Date
    /// Number of faces that were masked
    let maskedFaceCount: Int

    init(
        id: UUID = UUID(),
        thumbnail: UIImage,
        date: Date = .now,
        maskedFaceCount: Int
    ) {
        self.id = id
        self.thumbnail = thumbnail
        self.date = date
        self.maskedFaceCount = maskedFaceCount
    }
}
