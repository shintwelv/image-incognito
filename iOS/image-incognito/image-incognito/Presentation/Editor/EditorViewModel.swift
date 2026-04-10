//
//  EditorViewModel.swift
//  image-incognito
//
//  Presentation – AI Editor Screen ViewModel
//  Manages face detection, masking state, style, and adjustment controls.
//  Vision dependency removed: delegates to DetectFacesUseCase (Data layer).
//

import SwiftUI
import Observation

@MainActor
@Observable
final class EditorViewModel {

    // MARK: - Source

    let sourceImage: UIImage

    // MARK: - Face detection state

    var faces: [FaceBox] = []
    var isDetecting: Bool = false
    /// True only after the first detection run finishes (success or failure).
    /// Prevents the "no faces found" empty state from flashing before detection starts.
    var detectionCompleted: Bool = false

    // MARK: - Style & adjustments

    var selectedStyle: MaskingStyle = .blurredGlass
    /// Fill color used for the solidClean mask style.
    var solidCleanColor: Color = Color.appPrimary
    /// Masking intensity: 0 (transparent) → 1 (fully opaque).
    var intensity: Double = 0.75
    /// Bounding-box size multiplier: 0.5 (tighter) → 2.0 (larger).
    var sizeMultiplier: Double = 1.0
    /// Controls whether the adjustment sliders are visible.
    var showAdjustmentSliders: Bool = false

    // MARK: - Export state

    /// True while the mask is being baked into the image pixels.
    var isRendering: Bool = false
    /// Set once rendering completes; triggers navigation to ExportView.
    var renderedImage: UIImage? = nil

    // MARK: - Use Cases

    private let detectFacesUseCase: DetectFacesUseCase
    private let renderMaskUseCase: RenderMaskUseCase

    // MARK: - Init

    init(
        sourceImage: UIImage,
        detectFacesUseCase: DetectFacesUseCase = DetectFacesUseCase(repository: FaceDetectionService()),
        renderMaskUseCase: RenderMaskUseCase = RenderMaskUseCase(repository: MaskRenderingService())
    ) {
        self.sourceImage = sourceImage
        self.detectFacesUseCase = detectFacesUseCase
        self.renderMaskUseCase = renderMaskUseCase
    }

    // MARK: - Face Detection

    func detectFaces() async throws {
        guard !isDetecting else { return }
        isDetecting = true
        defer {
            isDetecting = false
            detectionCompleted = true
        }

        let detected = try await detectFacesUseCase.execute(image: sourceImage)
        // Apply the currently selected style to all newly detected faces.
        faces = detected.map { FaceBox(id: $0.id, rect: $0.rect, isMasked: $0.isMasked, style: selectedStyle) }
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

    // MARK: - Export

    /// Renders all active masks onto the source image and returns the result.
    func renderImage() async -> UIImage {
        let result = try? await renderMaskUseCase.execute(
            image: sourceImage,
            faces: faces,
            intensity: intensity,
            sizeMultiplier: sizeMultiplier,
            solidCleanColor: UIColor(solidCleanColor)
        )
        return result ?? sourceImage
    }

    /// Bakes all active masks onto the source image on a background thread,
    /// then sets `renderedImage` to trigger navigation to ExportView.
    func exportTapped() async {
        guard !isRendering else { return }
        AppHaptics.medium()
        isRendering = true

        let result = try? await renderMaskUseCase.execute(
            image: sourceImage,
            faces: faces,
            intensity: intensity,
            sizeMultiplier: sizeMultiplier,
            solidCleanColor: UIColor(solidCleanColor)
        )

        isRendering = false
        // Fall back to sourceImage if rendering failed (e.g. no faces masked)
        renderedImage = result ?? sourceImage
    }
}

