//
//  FaceSelectionHitTester.swift
//  image-incognito
//
//  Resolves which face overlay should receive a tap inside the editor canvas.
//

import CoreGraphics
import Foundation

enum FaceSelectionHitTester {

    nonisolated static func faceID(
        at point: CGPoint,
        faces: [FaceBox],
        imageRect: CGRect
    ) -> UUID? {
        guard imageRect.contains(point) else { return nil }

        return faces.reversed().first { face in
            overlayFrame(for: face, imageRect: imageRect).contains(point)
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

    /// Maps a normalized FaceBox rect to an absolute CGRect within `imageRect`,
    /// scaled by `sizeMultiplier` about the face center.
    nonisolated static func overlayFrame(for face: FaceBox, imageRect: CGRect) -> CGRect {
        let base = CGRect(
            x: imageRect.minX + face.rect.minX * imageRect.width,
            y: imageRect.minY + face.rect.minY * imageRect.height,
            width: face.rect.width * imageRect.width,
            height: face.rect.height * imageRect.height
        )
        guard face.isMasked else { return base }

        let scale = face.sizeMultiplier
        let newWidth = base.width * scale
        let newHeight = base.height * scale
        return CGRect(
            x: base.midX - newWidth / 2,
            y: base.midY - newHeight / 2,
            width: newWidth,
            height: newHeight
        )
    }
}
