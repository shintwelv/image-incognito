//
//  MaskRenderingRepositoryProtocol.swift
//  image-incognito
//
//  Domain Interface – Contract for compositing face masks onto an image.
//  The Data layer (MaskRenderingService) conforms to this protocol.
//

import UIKit

protocol MaskRenderingRepositoryProtocol: Sendable {
    /// Composites all active masks from `faces` onto `image` and returns
    /// the resulting UIImage. Runs on a background executor.
    func render(
        image: UIImage,
        faces: [FaceBox],
        solidCleanColor: UIColor
    ) async throws -> UIImage
}
