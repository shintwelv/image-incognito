//
//  FaceBox.swift
//  image-incognito
//
//  Domain Entity – A detected face and its normalized bounding box.
//  This is a detection DTO only: masking/editing state lives on `MaskRegion`.
//  `rect` uses top-left origin, normalized to [0, 1] relative to the source image.
//

import Foundation

nonisolated struct FaceBox: Identifiable, Sendable, Equatable {
    let id: UUID
    /// Normalized bounding box (top-left origin, values 0–1).
    var rect: CGRect

    init(id: UUID = UUID(), rect: CGRect) {
        self.id = id
        self.rect = rect
    }
}
