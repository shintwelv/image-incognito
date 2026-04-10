//
//  RecentMaskingItem+UIImage.swift
//  image-incognito
//
//  Presentation helper – decodes the raw JPEG thumbnail stored in the Domain
//  entity back into a UIImage for display. Lives in the Presentation layer so
//  the Domain entity remains UIKit-free.
//

import UIKit

extension RecentMaskingItem {
    /// Decodes `thumbnailData` into a UIImage. Returns nil if the data is invalid.
    var thumbnailImage: UIImage? {
        UIImage(data: thumbnailData)
    }
}
