//
//  MaskRenderingService.swift
//  image-incognito
//
//  Data Service – Composites included mask regions onto the source UIImage
//  using Core Image. Conforms to MaskRenderingRepositoryProtocol; CPU-bound
//  rendering runs on a background executor via Task.detached.
//

@preconcurrency import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

final class MaskRenderingService: MaskRenderingRepositoryProtocol {

    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    // MARK: - MaskRenderingRepositoryProtocol

    /// Composites all included regions onto `image` on a background thread.
    nonisolated func render(
        image: UIImage,
        regions: [MaskRegion],
        solidCleanColor: UIColor = UIColor(red: 94 / 255, green: 92 / 255, blue: 230 / 255, alpha: 1)
    ) async throws -> UIImage {
        // Capture self weakly to allow deallocation during long renders.
        let result = try await Task.detached(priority: .userInitiated) { [self] in
            try self.renderSync(
                image: image,
                regions: regions,
                solidCleanColor: solidCleanColor
            )
        }.value
        return result
    }

    // MARK: - Synchronous core (background-thread safe)

    nonisolated private func renderSync(
        image: UIImage,
        regions: [MaskRegion],
        solidCleanColor: UIColor
    ) throws -> UIImage {
        // Normalize to .up before any CGImage operations.
        // UIGraphicsImageRenderer + image.draw() both respect UIImage.imageOrientation,
        // but CGImage.cropping(to:) operates on raw, unrotated pixels. For a portrait
        // photo (imageOrientation=.right) the raw CGImage is landscape, so rect-based
        // cropping would hit the wrong region and produce rotated/misaligned masks.
        let image = normalizeOrientation(image)
        let size = image.size
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(at: .zero)

            for region in regions where region.isIncluded {
                let rect = pointRect(for: region, imageSize: size)
                guard rect.width > 1, rect.height > 1 else { continue }

                switch region.style {
                case .blurredGlass: applyBlur(rect: rect, region: region, image: image)
                case .pixelArt:     applyPixelArt(rect: rect, region: region, image: image)
                case .crystalize:   applyCrystalize(rect: rect, region: region, image: image)
                case .solidClean:   applySolid(rect: rect, region: region, color: solidCleanColor)
                case .emojiOverlay: applyEmojiOverlay(rect: rect, region: region)
                }
            }
        }
    }

    // MARK: - Orientation normalisation

    /// Redraws `image` into a new UIImage with `imageOrientation == .up` so that
    /// `image.cgImage` pixel coordinates match the display coordinate space.
    /// This is a no-op for images already in the `.up` orientation.
    nonisolated private func normalizeOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false
        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(at: .zero)
        }
    }

    // MARK: - Rect mapping

    /// Converts a region's normalized rect to point coordinates. Faces are
    /// expanded by `sizeMultiplier`; manual regions keep their drawn rect.
    /// The result is clamped to the image bounds.
    nonisolated private func pointRect(for region: MaskRegion, imageSize: CGSize) -> CGRect {
        let normalized = RegionGeometry.convert(region.rect, to: region.shape)
        let base = CGRect(
            x: normalized.minX * imageSize.width,
            y: normalized.minY * imageSize.height,
            width: normalized.width * imageSize.width,
            height: normalized.height * imageSize.height
        )

        let multiplier = region.source == .detectedFace ? region.sizeMultiplier : 1.0
        let w = base.width * multiplier
        let h = base.height * multiplier
        let expanded = CGRect(
            x: base.midX - w / 2,
            y: base.midY - h / 2,
            width: w,
            height: h
        )

        let bounds = CGRect(origin: .zero, size: imageSize)
        let clamped = expanded.intersection(bounds)
        return clamped.isNull ? .zero : clamped
    }

    /// Converts a point rect to CGImage pixel coords, clamped to the image bounds.
    nonisolated private func pixelBounds(for rect: CGRect, scale: CGFloat, cgImage: CGImage) -> CGRect {
        rect
            .applying(CGAffineTransform(scaleX: scale, y: scale))
            .intersection(CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
    }

    /// Returns the clipping path for a region shape. Circles use a square rect,
    /// so an oval clip renders a circle.
    nonisolated private func clipPath(for shape: MaskRegion.Shape, rect: CGRect) -> UIBezierPath {
        switch shape {
        case .rectangle:
            return UIBezierPath(rect: rect)
        case .ellipse, .circle:
            return UIBezierPath(ovalIn: rect)
        }
    }

    // MARK: - Blur (blurredGlass)

    nonisolated private func applyBlur(rect: CGRect, region: MaskRegion, image: UIImage) {
        guard
            let ctx = UIGraphicsGetCurrentContext(),
            let blurred = makeBlurredCrop(of: image, rect: rect, intensity: region.intensity)
        else { return }

        ctx.saveGState()
        ctx.addPath(clipPath(for: region.shape, rect: rect).cgPath)
        ctx.clip()
        blurred.draw(in: rect)
        ctx.restoreGState()
    }

    nonisolated private func makeBlurredCrop(of image: UIImage, rect: CGRect, intensity: Double) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let bounds = pixelBounds(for: rect, scale: image.scale, cgImage: cgImage)
        guard bounds.width > 0, bounds.height > 0,
              let cropped = cgImage.cropping(to: bounds) else { return nil }

        let originalExtent = CGRect(x: 0, y: 0, width: cropped.width, height: cropped.height)
        let ci = CIImage(cgImage: cropped).clampedToExtent()
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = ci
        let minEdge = min(CGFloat(cropped.width), CGFloat(cropped.height))
        filter.radius = Float(minEdge * intensity)

        guard let output = filter.outputImage?.cropped(to: originalExtent),
              let result = ciContext.createCGImage(output, from: originalExtent) else { return nil }
        return UIImage(cgImage: result, scale: image.scale, orientation: .up)
    }

    // MARK: - Pixelate (pixelArt)

    nonisolated private func applyPixelArt(rect: CGRect, region: MaskRegion, image: UIImage) {
        guard
            let ctx = UIGraphicsGetCurrentContext(),
            let pixelated = makePixelateCrop(of: image, rect: rect, intensity: region.intensity)
        else { return }

        ctx.saveGState()
        ctx.addPath(clipPath(for: region.shape, rect: rect).cgPath)
        ctx.clip()
        pixelated.draw(in: rect)
        ctx.restoreGState()
    }

    nonisolated private func makePixelateCrop(of image: UIImage, rect: CGRect, intensity: Double) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let bounds = pixelBounds(for: rect, scale: image.scale, cgImage: cgImage)
        guard bounds.width > 0, bounds.height > 0,
              let cropped = cgImage.cropping(to: bounds) else { return nil }

        let ci = CIImage(cgImage: cropped)
        let filter = CIFilter.pixellate()
        filter.inputImage = ci

        let minEdge = min(ci.extent.width, ci.extent.height)
        let maxScale = Float(minEdge * 0.25)
        filter.scale = 1.0 + (maxScale - 1.0) * Float(intensity)
        filter.center = CGPoint(x: ci.extent.midX, y: ci.extent.midY)

        guard let output = filter.outputImage,
              let result = ciContext.createCGImage(output, from: ci.extent) else { return nil }
        return UIImage(cgImage: result, scale: image.scale, orientation: .up)
    }

    // MARK: - Crystalize (crystalize)

    nonisolated private func applyCrystalize(rect: CGRect, region: MaskRegion, image: UIImage) {
        guard
            let ctx = UIGraphicsGetCurrentContext(),
            let crystalized = makeCrystalizeCrop(of: image, rect: rect, intensity: region.intensity)
        else { return }

        ctx.saveGState()
        ctx.addPath(clipPath(for: region.shape, rect: rect).cgPath)
        ctx.clip()
        crystalized.draw(in: rect)
        ctx.restoreGState()
    }

    nonisolated private func makeCrystalizeCrop(of image: UIImage, rect: CGRect, intensity: Double) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let bounds = pixelBounds(for: rect, scale: image.scale, cgImage: cgImage)
        guard bounds.width > 0, bounds.height > 0,
              let cropped = cgImage.cropping(to: bounds) else { return nil }

        let ci = CIImage(cgImage: cropped)
        let filter = CIFilter.crystallize()
        filter.inputImage = ci

        let minEdge = min(ci.extent.width, ci.extent.height)
        let maxRadius = Float(minEdge * 0.3)
        filter.radius = 1.0 + (maxRadius - 1.0) * Float(intensity)
        filter.center = CGPoint(x: ci.extent.midX, y: ci.extent.midY)

        guard let output = filter.outputImage,
              let result = ciContext.createCGImage(output, from: ci.extent) else { return nil }
        return UIImage(cgImage: result, scale: image.scale, orientation: .up)
    }

    // MARK: - Solid fill (solidClean)

    nonisolated private func applySolid(rect: CGRect, region: MaskRegion, color: UIColor) {
        color.withAlphaComponent(region.intensity).setFill()
        clipPath(for: region.shape, rect: rect).fill()
    }

    // MARK: - Emoji Overlay (emojiOverlay)

    nonisolated private func applyEmojiOverlay(rect: CGRect, region: MaskRegion) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.saveGState()

        let emoji = region.selectedEmoji.isEmpty ? "😎" : region.selectedEmoji
        let side = min(rect.width, rect.height)
        let fontSize = max(8.0, side * 0.85)
        let font = UIFont.systemFont(ofSize: fontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]

        let string = NSString(string: emoji)
        let textSize = string.size(withAttributes: attributes)

        let drawRect = CGRect(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )

        ctx.setAlpha(CGFloat(region.intensity))
        string.draw(in: drawRect, withAttributes: attributes)

        ctx.restoreGState()
    }
}
