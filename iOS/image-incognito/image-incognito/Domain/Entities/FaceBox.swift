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
    /// Masking intensity: 0 (transparent) → 1 (fully opaque).
    var intensity: Double
    /// Bounding-box size multiplier: 0.5 (tighter) → 2.0 (larger).
    var sizeMultiplier: Double

    init(
        id: UUID = UUID(),
        rect: CGRect,
        isMasked: Bool = true,
        style: MaskingStyle = .blurredGlass,
        intensity: Double = 0.75,
        sizeMultiplier: Double = 1.0
    ) {
        self.id = id
        self.rect = rect
        self.isMasked = isMasked
        self.style = style
        self.intensity = intensity
        self.sizeMultiplier = sizeMultiplier
    }
}
