//
//  MaskRegion.swift
//  image-incognito
//
//  Domain Entity – A maskable region on a photo. Detected faces become
//  `.detectedFace` suggestions; user-drawn areas are `.manual`.
//  `rect` uses top-left origin, normalized to [0, 1] relative to the image.
//  Circles keep a square rect (width == height) so an oval clip renders a circle.
//

import Foundation

nonisolated struct MaskRegion: Identifiable, Sendable, Equatable {

    // MARK: - Source

    enum Source: Sendable, Equatable {
        /// A face proposal produced by Vision detection.
        case detectedFace
        /// A region drawn by the user (rectangle, ellipse, or circle).
        case manual
    }

    // MARK: - Shape

    enum Shape: String, Sendable, Equatable, CaseIterable, Identifiable {
        case rectangle
        case ellipse
        case circle

        var id: String { rawValue }
    }

    // MARK: - Stored state

    let id: UUID
    var source: Source
    var shape: Shape {
        didSet {
            guard oldValue != shape else { return }
            rect = RegionGeometry.convert(rect, to: shape)
        }
    }

    /// Normalized bounding box (top-left origin, values 0–1).
    /// Always clamped into the unit square; circles are always square.
    var rect: CGRect {
        didSet {
            rect = RegionGeometry.convert(rect, to: shape)
        }
    }

    /// Whether this region is included when rendering.
    var isIncluded: Bool
    /// The visual style applied when included.
    var style: MaskingStyle
    /// Masking intensity: 0 (transparent) → 1 (fully opaque).
    var intensity: Double
    /// Bounding-box size multiplier: faces only. Manual regions always use 1.0.
    var sizeMultiplier: Double
    /// Selected emoji when style is `.emojiOverlay`.
    var selectedEmoji: String
    /// The detected face this region came from. Manual regions are `nil`.
    var linkedFaceID: UUID?

    // MARK: - Init

    init(
        id: UUID = UUID(),
        source: Source,
        shape: Shape,
        rect: CGRect,
        isIncluded: Bool = true,
        style: MaskingStyle = .blurredGlass,
        intensity: Double = 0.75,
        sizeMultiplier: Double = 1.0,
        selectedEmoji: String = "😎",
        linkedFaceID: UUID? = nil
    ) {
        self.id = id
        self.source = source
        self.shape = shape
        self.rect = RegionGeometry.convert(rect, to: shape)
        self.isIncluded = isIncluded
        self.style = style
        self.intensity = intensity
        self.sizeMultiplier = source == .manual ? 1.0 : sizeMultiplier
        self.selectedEmoji = selectedEmoji
        self.linkedFaceID = source == .detectedFace ? linkedFaceID : nil
    }

    // MARK: - Convenience

    var isManual: Bool { source == .manual }
    var isFace: Bool { source == .detectedFace }
}
