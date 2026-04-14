//
//  MaskRenderingService.swift
//  image-incognito
//
//  Data Service – Composites face masks onto the source UIImage using Core Image.
//  Conforms to MaskRenderingRepositoryProtocol; CPU-bound rendering runs on a
//  background executor via Task.detached.
//

@preconcurrency import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

final class MaskRenderingService: MaskRenderingRepositoryProtocol {

    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    // MARK: - MaskRenderingRepositoryProtocol

    /// Composites all active masks onto `image` on a background thread.
    nonisolated func render(
        image: UIImage,
        faces: [FaceBox],
        solidCleanColor: UIColor = UIColor(red: 94/255, green: 92/255, blue: 230/255, alpha: 1)
    ) async throws -> UIImage {
        // Capture self weakly to allow deallocation during long renders.
        let result = try await Task.detached(priority: .userInitiated) { [self] in
            try self.renderSync(
                image: image,
                faces: faces,
                solidCleanColor: solidCleanColor
            )
        }.value
        return result
    }

    // MARK: - Synchronous core (background-thread safe)

    nonisolated private func renderSync(
        image: UIImage,
        faces: [FaceBox],
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

            for face in faces where face.isMasked {
                let rect = pointRect(
                    normalizedRect: face.rect,
                    imageSize: size,
                    sizeMultiplier: face.sizeMultiplier
                )
                guard rect.width > 1, rect.height > 1 else { continue }

                switch face.style {
                case .blurredGlass: applyBlur(rect: rect, image: image, intensity: face.intensity)
                case .pixelArt:     applyPixelArt(rect: rect, image: image, intensity: face.intensity)
                case .solidClean:   applySolid(rect: rect, intensity: face.intensity, color: solidCleanColor)
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

    /// Converts a normalized (0–1, top-left origin) rect to point coordinates,
    /// expanded by `sizeMultiplier` and clamped to the image bounds.
    nonisolated private func pointRect(normalizedRect: CGRect, imageSize: CGSize, sizeMultiplier: Double) -> CGRect {
        let base = CGRect(
            x: normalizedRect.minX * imageSize.width,
            y: normalizedRect.minY * imageSize.height,
            width: normalizedRect.width * imageSize.width,
            height: normalizedRect.height * imageSize.height
        )
        let w = base.width * sizeMultiplier
        let h = base.height * sizeMultiplier
        let expanded = CGRect(
            x: base.midX - w / 2,
            y: base.midY - h / 2,
            width: w,
            height: h
        )
        return expanded.intersection(CGRect(origin: .zero, size: imageSize))
    }

    /// Converts a point rect to CGImage pixel coords, clamped to the image bounds.
    nonisolated private func pixelBounds(for rect: CGRect, scale: CGFloat, cgImage: CGImage) -> CGRect {
        rect
            .applying(CGAffineTransform(scaleX: scale, y: scale))
            .intersection(CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
    }

    // MARK: - Blur (blurredGlass)

    nonisolated private func applyBlur(rect: CGRect, image: UIImage, intensity: Double) {
        guard
            let ctx = UIGraphicsGetCurrentContext(),
            let blurred = makeBlurredCrop(of: image, rect: rect, intensity: intensity)
        else { return }

        ctx.saveGState()
        ctx.addPath(UIBezierPath(ovalIn: rect).cgPath)
        ctx.clip()
        blurred.draw(in: rect)
        ctx.restoreGState()
    }

    nonisolated private func makeBlurredCrop(of image: UIImage, rect: CGRect, intensity: Double) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let bounds = pixelBounds(for: rect, scale: image.scale, cgImage: cgImage)
        guard bounds.width > 0, bounds.height > 0,
              let cropped = cgImage.cropping(to: bounds) else { return nil }

        let ci = CIImage(cgImage: cropped)
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = ci
        let minEdge = CGFloat(cropped.width)
        let maxRadius: CGFloat = minEdge * 0.1
        filter.radius = Float(maxRadius * intensity)

        guard let output = filter.outputImage,
              let result = ciContext.createCGImage(output, from: ci.extent) else { return nil }
        return UIImage(cgImage: result, scale: image.scale, orientation: .up)
    }

    // MARK: - Pixelate (pixelArt)

    nonisolated private func applyPixelArt(rect: CGRect, image: UIImage, intensity: Double) {
        guard
            let ctx = UIGraphicsGetCurrentContext(),
            let pixelated = makePixelateCrop(of: image, rect: rect, intensity: intensity)
        else { return }

        ctx.saveGState()
        ctx.addPath(UIBezierPath(ovalIn: rect).cgPath)
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
        let maxScale = Float(minEdge * 0.08) // it is natural to set block's size between shorter edge's 5% ~ 8%
        filter.scale = 1.0 + (maxScale - 1.0) * Float(intensity)
        filter.center = CGPoint(x: ci.extent.midX, y: ci.extent.midY)

        guard let output = filter.outputImage,
              let result = ciContext.createCGImage(output, from: ci.extent) else { return nil }
        return UIImage(cgImage: result, scale: image.scale, orientation: .up)
    }

    // MARK: - Solid fill (solidClean)

    nonisolated private func applySolid(rect: CGRect, intensity: Double, color: UIColor) {
        color.withAlphaComponent(intensity).setFill()
        UIBezierPath(ovalIn: rect).fill()
    }
}
