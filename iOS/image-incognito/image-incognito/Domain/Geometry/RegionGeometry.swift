//
//  RegionGeometry.swift
//  image-incognito
//
//  Domain Geometry – Shared normalization, clamping, circle invariants, and
//  hit testing for `MaskRegion`. The editor and the renderer use the same
//  helpers so drawn rects and baked masks always agree.
//

import CoreGraphics
import Foundation

nonisolated enum RegionGeometry {

    /// Smallest allowed normalized width/height (diameter for circles).
    static let minimumNormalizedSize: CGFloat = 0.01

    // MARK: - Clamping

    /// Standardizes `rect`, clamps it into the unit square, and never returns
    /// a null/infinite rect. A rect entirely outside the image collapses to a
    /// zero-size rect anchored at the nearest unit-square edge.
    static func clamped(_ rect: CGRect) -> CGRect {
        let values = [rect.origin.x, rect.origin.y, rect.size.width, rect.size.height]
        guard values.allSatisfy(\.isFinite) else { return .zero }

        let standardized = rect.standardized
        let intersection = standardized.intersection(unitRect)
        guard !intersection.isNull, !intersection.isEmpty else {
            let anchor = CGPoint(
                x: clampedUnit(standardized.minX),
                y: clampedUnit(standardized.minY)
            )
            return CGRect(origin: anchor, size: .zero)
        }
        return intersection
    }

    // MARK: - Normalized rects

    /// Builds a clamped normalized rect from two drag points (any order).
    static func normalizedRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        let a = clampedPoint(start)
        let b = clampedPoint(end)
        return CGRect(
            x: min(a.x, b.x),
            y: min(a.y, b.y),
            width: abs(b.x - a.x),
            height: abs(b.y - a.y)
        )
    }

    /// A square rect centered on `center`, with no clamping applied.
    static func squareRect(center: CGPoint, side: CGFloat) -> CGRect {
        let side = max(0, side)
        return CGRect(
            x: center.x - side / 2,
            y: center.y - side / 2,
            width: side,
            height: side
        )
    }

    /// Builds a circle rect from a drag box: the center of the drag box becomes
    /// the circle center, and the longest edge becomes the diameter so the
    /// swept area is covered. The center is clamped and the diameter shrunk so
    /// the whole circle stays inside the unit square. Always `width == height`.
    static func circleRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        let a = clampedPoint(start)
        let b = clampedPoint(end)
        let center = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        let side = max(abs(b.x - a.x), abs(b.y - a.y))
        return circleRect(center: center, side: side)
    }

    /// Squares and clamps an arbitrary rect for circular rendering. The center
    /// is preserved; `max(width, height)` becomes the diameter.
    static func convert(_ rect: CGRect, to shape: MaskRegion.Shape) -> CGRect {
        switch shape {
        case .rectangle, .ellipse:
            return clamped(rect)
        case .circle:
            let standardized = clamped(rect).standardized
            return circleRect(
                center: CGPoint(x: standardized.midX, y: standardized.midY),
                side: max(standardized.width, standardized.height)
            )
        }
    }

    // MARK: - Size

    /// `true` when both normalized dimensions reach `minimumNormalizedSize`.
    /// For circles the square rect means both dimensions equal the diameter.
    static func isAtLeastMinimumSize(_ rect: CGRect) -> Bool {
        let standardized = rect.standardized
        return standardized.width >= minimumNormalizedSize
            && standardized.height >= minimumNormalizedSize
    }

    // MARK: - Hit testing

    /// Rect hit testing for rectangles, point-in-ellipse for ellipse/circle.
    static func contains(_ point: CGPoint, in rect: CGRect, shape: MaskRegion.Shape) -> Bool {
        let standardized = rect.standardized
        guard standardized.width > 0, standardized.height > 0 else { return false }

        switch shape {
        case .rectangle:
            return standardized.contains(point)
        case .ellipse, .circle:
            let dx = (point.x - standardized.midX) / (standardized.width / 2)
            let dy = (point.y - standardized.midY) / (standardized.height / 2)
            return (dx * dx + dy * dy) <= 1
        }
    }

    // MARK: - Coordinate helpers

    /// Maps a point from `imageRect` (display space) into normalized unit space.
    static func normalizedPoint(_ point: CGPoint, in imageRect: CGRect) -> CGPoint {
        guard imageRect.width > 0, imageRect.height > 0,
              point.x.isFinite, point.y.isFinite else { return .zero }
        return CGPoint(
            x: (point.x - imageRect.minX) / imageRect.width,
            y: (point.y - imageRect.minY) / imageRect.height
        )
    }

    // MARK: - Private

    private static let unitRect = CGRect(x: 0, y: 0, width: 1, height: 1)

    /// Clamps a circle's center into the unit square, then shrinks its diameter
    /// so the whole square fits on every side.
    private static func circleRect(center: CGPoint, side: CGFloat) -> CGRect {
        let center = clampedPoint(center)
        let maxSide = 2 * min(min(center.x, 1 - center.x), min(center.y, 1 - center.y))
        let side = min(max(0, side), maxSide)
        return squareRect(center: center, side: side)
    }

    private static func clampedPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(x: clampedUnit(point.x), y: clampedUnit(point.y))
    }

    private static func clampedUnit(_ value: CGFloat) -> CGFloat {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}
