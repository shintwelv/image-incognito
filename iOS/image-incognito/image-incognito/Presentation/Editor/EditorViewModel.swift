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
    var solidCleanColor: Color = Color.appPrimary
    var selectedFaceID: UUID?

    var intensity: Double {
        get {
            guard let id = selectedFaceID, let face = faces.first(where: { $0.id == id }) else { return 0.75 }
            return face.intensity
        }
        set {
            guard let id = selectedFaceID, let index = faces.firstIndex(where: { $0.id == id }) else { return }
            faces[index].intensity = newValue
        }
    }

    var sizeMultiplier: Double {
        get {
            guard let id = selectedFaceID, let face = faces.first(where: { $0.id == id }) else { return 1.0 }
            return face.sizeMultiplier
        }
        set {
            guard let id = selectedFaceID, let index = faces.firstIndex(where: { $0.id == id }) else { return }
            faces[index].sizeMultiplier = newValue
        }
    }

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
        faces = detected.map { FaceBox(id: $0.id, rect: $0.rect, isMasked: $0.isMasked, style: selectedStyle) }
        selectedFaceID = faces.first?.id
    }

    // MARK: - Intent

    /// Toggle masking on/off for a specific face.
    func toggleMask(id: UUID) {
        selectedFaceID = id
        guard let index = faces.firstIndex(where: { $0.id == id }) else { return }
        AppHaptics.medium()
        faces[index].isMasked.toggle()
    }

    /// Select a face to show adjustment sliders without toggling mask.
    func selectFace(id: UUID) {
        if selectedFaceID != id {
            AppHaptics.selection()
            selectedFaceID = id
            withAnimation(AppAnimation.standard) {
                showAdjustmentSliders = true
            }
        }
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
            solidCleanColor: UIColor(solidCleanColor)
        )

        isRendering = false
        // Fall back to sourceImage if rendering failed (e.g. no faces masked)
        renderedImage = result ?? sourceImage
    }
}
