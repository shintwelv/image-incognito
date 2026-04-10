//
//  FaceBox.swift
//  image-incognito
//
//  Domain Entity – A detected face with its normalized bounding box and masking state.
//  `rect` uses top-left origin, normalized to [0, 1] relative to the source image.
//

import Foundation

nonisolated struct FaceBox: Identifiable, Sendable {
    let id: UUID
    /// Normalized bounding box (top-left origin, values 0–1).
    var rect: CGRect
    /// Whether this face is currently being masked.
    var isMasked: Bool
    /// The visual style applied when `isMasked` is true.
    var style: MaskingStyle

    init(
        id: UUID = UUID(),
        rect: CGRect,
        isMasked: Bool = true,
        style: MaskingStyle = .blurredGlass
    ) {
        self.id = id
        self.rect = rect
        self.isMasked = isMasked
        self.style = style
    }
}
