//
//  MaskRenderingRepositoryProtocol.swift
//  image-incognito
//
//  Domain Interface – Contract for compositing mask regions onto an image.
//  The Data layer (MaskRenderingService) conforms to this protocol.
//

import UIKit

protocol MaskRenderingRepositoryProtocol: Sendable {
    /// Composites all included regions onto `image` and returns the resulting
    /// UIImage. Runs on a background executor.
    func render(
        image: UIImage,
        regions: [MaskRegion],
        solidCleanColor: UIColor
    ) async throws -> UIImage
}

extension MaskRenderingRepositoryProtocol {
    /// Compatibility adapter for the face-only editor flow. Maps each
    /// `FaceBox` to a `.detectedFace` ellipse region and forwards to the
    /// regions-based requirement.
    func render(
        image: UIImage,
        faces: [FaceBox],
        solidCleanColor: UIColor = UIColor(red: 94 / 255, green: 92 / 255, blue: 230 / 255, alpha: 1)
    ) async throws -> UIImage {
        let regions = faces.map { face in
            MaskRegion(
                id: face.id,
                source: .detectedFace,
                shape: .ellipse,
                rect: face.rect,
                isIncluded: face.isMasked,
                style: face.style,
                intensity: face.intensity,
                sizeMultiplier: face.sizeMultiplier,
                selectedEmoji: face.selectedEmoji,
                linkedFaceID: face.id
            )
        }
        return try await render(
            image: image,
            regions: regions,
            solidCleanColor: solidCleanColor
        )
    }
}
