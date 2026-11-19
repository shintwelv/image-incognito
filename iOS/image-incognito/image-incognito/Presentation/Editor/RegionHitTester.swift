//
//  RegionHitTester.swift
//  image-incognito
//
//  Resolves which region overlay receives a tap inside the editor canvas and
//  maps normalized region rects into display space.
//

import CoreGraphics
import Foundation

enum RegionHitTester {

    /// Returns the top-most region under `point` (last in draw order wins).
    nonisolated static func regionID(
        at point: CGPoint,
        regions: [MaskRegion],
        imageRect: CGRect
    ) -> UUID? {
        guard imageRect.contains(point) else { return nil }

        let normalized = RegionGeometry.normalizedPoint(point, in: imageRect)
        return regions.reversed().first { region in
            RegionGeometry.contains(
                normalized,
                in: normalizedVisualRect(for: region),
                shape: region.shape
            )
        }?.id
    }

    /// Calculates the rendered CGRect of a `.scaledToFit` image inside `containerSize`.
    nonisolated static func imageRenderRect(in containerSize: CGSize, imageSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGRect(origin: .zero, size: containerSize)
        }
        let containerAspect = containerSize.width / containerSize.height
        let imageAspect = imageSize.width / imageSize.height

        let renderSize: CGSize
        if imageAspect > containerAspect {
            let width = containerSize.width
            renderSize = CGSize(width: width, height: width / imageAspect)
        } else {
            let height = containerSize.height
            renderSize = CGSize(width: height * imageAspect, height: height)
        }

        return CGRect(
            x: (containerSize.width - renderSize.width) / 2,
            y: (containerSize.height - renderSize.height) / 2,
            width: renderSize.width,
            height: renderSize.height
        )
    }

    /// Maps a normalized region rect to an absolute CGRect within `imageRect`.
    /// Detected faces expand around their center by `sizeMultiplier`; manual
    /// regions render exactly as drawn.
    nonisolated static func overlayFrame(for region: MaskRegion, imageRect: CGRect) -> CGRect {
        let visual = normalizedVisualRect(for: region)
        return CGRect(
            x: imageRect.minX + visual.minX * imageRect.width,
            y: imageRect.minY + visual.minY * imageRect.height,
            width: visual.width * imageRect.width,
            height: visual.height * imageRect.height
        )
    }

    /// Normalized rect including a detected face's size multiplier.
    nonisolated static func normalizedVisualRect(for region: MaskRegion) -> CGRect {
        let base = RegionGeometry.convert(region.rect, to: region.shape)
        guard region.isFace else { return base }

        let scale = region.sizeMultiplier
        let width = base.width * scale
        let height = base.height * scale
        return CGRect(
            x: base.midX - width / 2,
            y: base.midY - height / 2,
            width: width,
            height: height
        )
    }
}
