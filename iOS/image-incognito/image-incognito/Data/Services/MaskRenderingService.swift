//
//  MaskRenderingService.swift
//  image-incognito
//
//  Data Service – Composites face masks onto the source UIImage using Core Image.
//  All work is done on a background thread; call via async Task.detached.
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

final class MaskRenderingService {

    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    // MARK: - Public API

    /// Returns a new UIImage with all active masks baked into the pixel data.
    func render(
        image: UIImage,
        faces: [FaceBox],
        intensity: Double,
        sizeMultiplier: Double
    ) throws -> UIImage {
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
                    sizeMultiplier: sizeMultiplier
                )
                guard rect.width > 1, rect.height > 1 else { continue }

                switch face.style {
                case .blurredGlass: applyBlur(rect: rect, image: image, intensity: intensity)
                case .pixelArt:     applyPixelArt(rect: rect, image: image, intensity: intensity)
                case .solidClean:   applySolid(rect: rect, intensity: intensity)
                }
            }
        }
    }

    // MARK: - Rect mapping

    /// Converts a normalized (0–1, top-left origin) rect to point coordinates,
    /// expanded by `sizeMultiplier` and clamped to the image bounds.
    private func pointRect(normalizedRect: CGRect, imageSize: CGSize, sizeMultiplier: Double) -> CGRect {
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
    private func pixelBounds(for rect: CGRect, scale: CGFloat, cgImage: CGImage) -> CGRect {
        rect
            .applying(CGAffineTransform(scaleX: scale, y: scale))
            .intersection(CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
    }

    // MARK: - Blur (blurredGlass)

    private func applyBlur(rect: CGRect, image: UIImage, intensity: Double) {
        guard
            let ctx = UIGraphicsGetCurrentContext(),
            let blurred = makeBlurredCrop(of: image, rect: rect, intensity: intensity)
        else { return }

        ctx.saveGState()
        ctx.addPath(UIBezierPath(roundedRect: rect, cornerRadius: 12).cgPath)
        ctx.clip()
        blurred.draw(in: rect)
        ctx.restoreGState()
    }

    private func makeBlurredCrop(of image: UIImage, rect: CGRect, intensity: Double) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let bounds = pixelBounds(for: rect, scale: image.scale, cgImage: cgImage)
        guard bounds.width > 0, bounds.height > 0,
              let cropped = cgImage.cropping(to: bounds) else { return nil }

        let ci = CIImage(cgImage: cropped)
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = ci
        filter.radius = Float(max(2, intensity * 28))

        guard let output = filter.outputImage,
              let result = ciContext.createCGImage(output, from: ci.extent) else { return nil }
        return UIImage(cgImage: result, scale: image.scale, orientation: .up)
    }

    // MARK: - Pixelate (pixelArt)

    private func applyPixelArt(rect: CGRect, image: UIImage, intensity: Double) {
        guard
            let ctx = UIGraphicsGetCurrentContext(),
            let pixelated = makePixelateCrop(of: image, rect: rect, intensity: intensity)
        else { return }

        ctx.saveGState()
        ctx.addPath(UIBezierPath(roundedRect: rect, cornerRadius: 12).cgPath)
        ctx.clip()
        pixelated.draw(in: rect)
        ctx.restoreGState()
    }

    private func makePixelateCrop(of image: UIImage, rect: CGRect, intensity: Double) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let bounds = pixelBounds(for: rect, scale: image.scale, cgImage: cgImage)
        guard bounds.width > 0, bounds.height > 0,
              let cropped = cgImage.cropping(to: bounds) else { return nil }

        let ci = CIImage(cgImage: cropped)
        let filter = CIFilter.pixellate()
        filter.inputImage = ci
        filter.scale = Float(max(6, intensity * 30))
        filter.center = CGPoint(x: ci.extent.midX, y: ci.extent.midY)

        guard let output = filter.outputImage,
              let result = ciContext.createCGImage(output, from: ci.extent) else { return nil }
        return UIImage(cgImage: result, scale: image.scale, orientation: .up)
    }

    // MARK: - Solid fill (solidClean)

    private func applySolid(rect: CGRect, intensity: Double) {
        // #5E5CE6 – App primary indigo
        UIColor(red: 94/255, green: 92/255, blue: 230/255, alpha: 0.55 + 0.35 * intensity)
            .setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 12).fill()
    }
}
