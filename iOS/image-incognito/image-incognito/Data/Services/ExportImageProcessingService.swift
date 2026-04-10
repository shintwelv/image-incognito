//
//  ExportImageProcessingService.swift
//  image-incognito
//
//  Data Service – Applies export settings (resolution, metadata stripping)
//  to a UIImage before saving or sharing.
//  Conforms to ExportProcessingRepositoryProtocol; CPU-bound work runs on a
//  background executor via Task.detached.
//

import UIKit
import ImageIO

final class ExportImageProcessingService: ExportProcessingRepositoryProtocol {

    // MARK: - ExportProcessingRepositoryProtocol

    /// Applies `settings` to `image` on a background thread and returns the result.
    func process(_ image: UIImage, settings: ExportSettings) async -> UIImage {
        await Task.detached(priority: .userInitiated) {
            self.applySettings(to: image, settings: settings)
        }.value
    }

    // MARK: - Pipeline

    private func applySettings(to image: UIImage, settings: ExportSettings) -> UIImage {
        let target = settings.keepOriginalResolution ? image : downsampled(image, maxDimension: 1080)
        return strippedMetadata(from: target, settings: settings)
    }

    // MARK: - Downsampling

    /// Downsamples `image` so its longest side fits within `maxDimension`, preserving aspect ratio.
    private func downsampled(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return image }

        let scale = maxDimension / longestSide
        let newSize = CGSize(
            width: (size.width * scale).rounded(),
            height: (size.height * scale).rounded()
        )
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Metadata Stripping

    /// Rewrites the image as JPEG via ImageIO, nulling out the requested metadata containers.
    private func strippedMetadata(from image: UIImage, settings: ExportSettings) -> UIImage {
        guard settings.removeExif || settings.removeLocation else { return image }

        guard let baseData = image.jpegData(compressionQuality: 1.0) as CFData?,
              let source = CGImageSourceCreateWithData(baseData, nil),
              let uti = CGImageSourceGetType(source) else { return image }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, uti, 1, nil) else {
            return image
        }

        var properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] ?? [:]

        if settings.removeExif {
            properties[kCGImagePropertyExifDictionary] = nil
            properties[kCGImagePropertyTIFFDictionary] = nil
            properties[kCGImagePropertyGPSDictionary] = nil
            properties[kCGImagePropertyIPTCDictionary] = nil
        } else if settings.removeLocation {
            properties[kCGImagePropertyGPSDictionary] = nil
        }

        CGImageDestinationAddImageFromSource(destination, source, 0, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return image }

        return UIImage(data: output as Data, scale: image.scale) ?? image
    }
}
