//
//  ExportImageProcessingService.swift
//  image-incognito
//
//  Data Service – Applies export settings (resolution, metadata stripping)
//  to a UIImage before saving or sharing.
//  Conforms to ExportProcessingRepositoryProtocol; CPU-bound work runs on a
//  background executor via Task.detached.
//

@preconcurrency import UIKit
import ImageIO

struct ExportImageProcessingService: ExportProcessingRepositoryProtocol, Sendable {

    // MARK: - ExportProcessingRepositoryProtocol

    /// Applies `settings` to `image` on a background thread and returns the result.
    nonisolated func process(_ image: UIImage, settings: ExportSettings) async -> UIImage {
        await Task.detached(priority: .userInitiated) {
            applySettings(to: image, settings: settings)
        }.value
    }

    // MARK: - Pipeline

    nonisolated private func applySettings(to image: UIImage, settings: ExportSettings) -> UIImage {
        let target = settings.keepOriginalResolution ? image : downsampled(image, maxDimension: 1080)
        return strippedMetadata(from: target, settings: settings)
    }

    // MARK: - Downsampling

    /// Downsamples `image` so its longest side fits within `maxDimension`, preserving aspect ratio.
    /// Uses Core Graphics directly so the operation is safe to run off the main actor.
    nonisolated private func downsampled(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return image }

        let scale = maxDimension / longestSide
        let newWidth = Int((size.width * scale).rounded())
        let newHeight = Int((size.height * scale).rounded())

        guard let cgImage = image.cgImage else { return image }
        let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        ) else { return image }

        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        guard let resultCG = context.makeImage() else { return image }
        return UIImage(cgImage: resultCG, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Metadata Stripping

    /// Rewrites the image as JPEG via ImageIO, nulling out the requested metadata containers.
    nonisolated private func strippedMetadata(from image: UIImage, settings: ExportSettings) -> UIImage {
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
