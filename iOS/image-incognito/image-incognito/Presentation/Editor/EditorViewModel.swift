//
//  EditorViewModel.swift
//  image-incognito
//
//  Presentation – AI Editor Screen ViewModel
//  Manages face detection (Vision), masking state, style, and adjustment controls.
//

import SwiftUI
import Vision
import Observation

@Observable
final class EditorViewModel {

    // MARK: - Source

    let sourceImage: UIImage

    // MARK: - Face detection state

    var faces: [FaceBox] = []
    var isDetecting: Bool = false

    // MARK: - Style & adjustments

    var selectedStyle: MaskingStyle = .blurredGlass
    /// Masking intensity: 0 (transparent) → 1 (fully opaque).
    var intensity: Double = 0.75
    /// Bounding-box size multiplier: 0.5 (tighter) → 2.0 (larger).
    var sizeMultiplier: Double = 1.0
    /// Controls whether the adjustment sliders are visible.
    var showAdjustmentSliders: Bool = false

    // MARK: - Init

    init(sourceImage: UIImage) {
        self.sourceImage = sourceImage
    }

    // MARK: - Face Detection

    func detectFaces() async throws {
        guard !isDetecting else { return }
        await MainActor.run { isDetecting = true }
        defer { Task { @MainActor in self.isDetecting = false } }

        guard let cgImage = sourceImage.cgImage else { return }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try handler.perform([request])
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }

        let results = request.results ?? []
        let detected: [FaceBox] = results.map { observation in
            // Vision uses bottom-left origin; convert to top-left (UIKit/SwiftUI).
            let flipped = CGRect(
                x: observation.boundingBox.origin.x,
                y: 1 - observation.boundingBox.origin.y - observation.boundingBox.height,
                width: observation.boundingBox.width,
                height: observation.boundingBox.height
            )
            return FaceBox(rect: flipped, style: selectedStyle)
        }

        await MainActor.run {
            self.faces = detected
        }
    }

    // MARK: - Intent

    /// Toggle masking on/off for a specific face.
    func toggleMask(id: UUID) {
        guard let index = faces.firstIndex(where: { $0.id == id }) else { return }
        AppHaptics.medium()
        faces[index].isMasked.toggle()
    }

    /// Select a style pill. Tapping the active style toggles the adjustment panel.
    func selectStyle(_ style: MaskingStyle) {
        if selectedStyle == style {
            withAnimation(AppAnimation.standard) {
                showAdjustmentSliders.toggle()
            }
        } else {
            AppHaptics.selection()
            selectedStyle = style
            for index in faces.indices {
                faces[index].style = style
            }
            withAnimation(AppAnimation.standard) {
                showAdjustmentSliders = true
            }
        }
    }
}
