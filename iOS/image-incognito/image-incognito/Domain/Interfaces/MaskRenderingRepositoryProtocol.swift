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
