//
//  ExportProcessingRepositoryProtocol.swift
//  image-incognito
//
//  Domain Interface – Contract for applying export settings to an image
//  (resolution downsampling, metadata stripping) before saving or sharing.
//  The Data layer (ExportImageProcessingService) conforms to this protocol.
//

import UIKit

protocol ExportProcessingRepositoryProtocol: Sendable {
    /// Applies `settings` to `image` (resolution, metadata) and returns
    /// the processed result. Never throws — falls back to the original on error.
    func process(_ image: UIImage, settings: ExportSettings) async -> UIImage
}
