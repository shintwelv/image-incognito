//
//  EditorViewCoverageTests.swift
//  image-incognitoTests
//
//  Stable SwiftUI hosting tests for the review editor surfaces. These render
//  views into a real UIWindow (no snapshot files) so layout-time body code is
//  exercised without UI automation.
//

import SwiftUI
import Testing
import UIKit
@testable import image_incognito

@MainActor
@Suite("EditorViewCoverage")
struct EditorViewCoverageTests {

    // MARK: - Environment

    private let store: SettingsStore = {
        let store = SettingsStore()
        store.resetEmojiPresets()
        return store
    }()

    // MARK: - Helpers

    private func makeImage(color: UIColor = .systemBlue) -> UIImage {
        let size = CGSize(width: 300, height: 400)
        return UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func makeRegion(
        source: MaskRegion.Source = .manual,
        shape: MaskRegion.Shape = .rectangle,
        rect: CGRect = CGRect(x: 0.1, y: 0.1, width: 0.25, height: 0.2),
        isIncluded: Bool = true,
        style: MaskingStyle = .blurredGlass,
        emoji: String = "😎"
    ) -> MaskRegion {
        MaskRegion(
            source: source,
            shape: shape,
            rect: rect,
            isIncluded: isIncluded,
            style: style,
            selectedEmoji: emoji
        )
    }

    private func makeViewModel(
        regions: [MaskRegion] = [],
        selected: UUID? = nil,
        phase: EditorViewModel.Phase = .reviewing,
        detectionFailed: Bool = false
    ) -> EditorViewModel {
        let viewModel = EditorViewModel(sourceImage: makeImage())
        viewModel.phase = phase
        viewModel.regions = regions
        viewModel.selectedRegionID = selected ?? regions.first?.id
        viewModel.isAdjustmentPanelVisible = selected != nil
        viewModel.detectionFailed = detectionFailed
        return viewModel
    }

    /// Hosts `view` in a key window at a deterministic size, lays it out once,
    /// then releases the window/controller.
    private func host<V: View>(_ view: V, size: CGSize = CGSize(width: 390, height: 844)) {
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: size)
        window.rootViewController = controller
        window.makeKeyAndVisible()

        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        #expect(controller.view.window === window)
        window.isHidden = true
    }

    private func manualShapeSet() -> [MaskRegion] {
        [
            makeRegion(source: .detectedFace, shape: .ellipse, rect: CGRect(x: 0.08, y: 0.08, width: 0.25, height: 0.25)),
            makeRegion(shape: .rectangle, rect: CGRect(x: 0.1, y: 0.45, width: 0.35, height: 0.2), style: .solidClean),
            makeRegion(shape: .circle, rect: CGRect(x: 0.55, y: 0.45, width: 0.25, height: 0.25), isIncluded: false, style: .emojiOverlay, emoji: "🐱"),
            makeRegion(shape: .ellipse, rect: CGRect(x: 0.35, y: 0.72, width: 0.4, height: 0.2), style: .pixelArt)
        ]
    }

    // MARK: - RegionListView

    @Test("RegionListView hosts face, rectangle, circle, and ellipse rows")
    func regionListViewRows() {
        let regions = manualShapeSet()
        let viewModel = makeViewModel(regions: regions, selected: regions[1].id)

        host(RegionListView(viewModel: viewModel) {})
        #expect(viewModel.regions.count == 4)
    }

    @Test("RegionListView hosts the empty state")
    func regionListViewEmpty() {
        let viewModel = makeViewModel()

        host(RegionListView(viewModel: viewModel) {})
        #expect(viewModel.regions.isEmpty)
    }

    // MARK: - DrawRegionOverlay

    @Test("DrawRegionOverlay hosts rectangle, circle, and ellipse drawing modes")
    func drawRegionOverlayShapes() {
        let imageRect = CGRect(x: 20, y: 60, width: 350, height: 560)

        for shape in MaskRegion.Shape.allCases {
            var selectedShape: MaskRegion.Shape?
            var cancelled = false
            var committed: CGRect?

            let overlay = DrawRegionOverlay(
                imageRect: imageRect,
                selectedShape: shape,
                onShapeChange: { selectedShape = $0 },
                onCancel: { cancelled = true },
                onCommit: { committed = $0 }
            )

            host(overlay, size: CGSize(width: 390, height: 700))

            #expect(selectedShape == nil)
            #expect(cancelled == false)
            #expect(committed == nil)
        }
    }

    @Test("ShapePickerRow hosts every shape")
    func shapePickerRowHosts() {
        for shape in MaskRegion.Shape.allCases {
            var selected: MaskRegion.Shape?
            host(ShapePickerRow(selectedShape: shape, onSelect: { selected = $0 }))
            #expect(selected == nil)
        }
    }

    // MARK: - Editor state views

    @Test("Editor transient state views host")
    func editorStateViewsHost() {
        host(DetectingSkeletonView(), size: CGSize(width: 300, height: 240))
        host(NoFaceFoundView(onAddRegion: {}), size: CGSize(width: 320, height: 300))
        host(DetectionFailedView(onAddRegion: {}), size: CGSize(width: 320, height: 300))
        host(RenderingOverlayView(current: 2, total: 5), size: CGSize(width: 390, height: 844))
        host(RenderingOverlayView(current: 0, total: 0), size: CGSize(width: 390, height: 844))
    }

    // MARK: - AdjustmentSlidersView

    @Test("AdjustmentSlidersView hosts a manual region with shape picker and handles hint")
    func adjustmentSlidersManual() {
        let manual = makeRegion(shape: .circle, rect: CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3), style: .solidClean)
        var intensity = 0.6
        var sizeMultiplier = 1.0
        var color = Color.appPrimary
        var emoji = "😎"

        let view = AdjustmentSlidersView(
            intensity: Binding(get: { intensity }, set: { intensity = $0 }),
            sizeMultiplier: Binding(get: { sizeMultiplier }, set: { sizeMultiplier = $0 }),
            selectedStyle: .solidClean,
            solidCleanColor: Binding(get: { color }, set: { color = $0 }),
            selectedEmoji: Binding(get: { emoji }, set: { emoji = $0 }),
            region: manual,
            onToggleInclusion: {},
            onDelete: {},
            onApplyToAll: {},
            onShapeChange: { _ in }
        )
        .environment(store)

        host(view, size: CGSize(width: 390, height: 560))
        #expect(manual.shape == .circle)
    }

    @Test("AdjustmentSlidersView hosts a detected face with size slider and emoji picker")
    func adjustmentSlidersFace() {
        let face = makeRegion(source: .detectedFace, shape: .ellipse, rect: CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3), style: .emojiOverlay, emoji: "🐱")
        var intensity = 0.75
        var sizeMultiplier = 1.4
        var color = Color.appPrimary
        var emoji = "🐱"

        let view = AdjustmentSlidersView(
            intensity: Binding(get: { intensity }, set: { intensity = $0 }),
            sizeMultiplier: Binding(get: { sizeMultiplier }, set: { sizeMultiplier = $0 }),
            selectedStyle: .emojiOverlay,
            solidCleanColor: Binding(get: { color }, set: { color = $0 }),
            selectedEmoji: Binding(get: { emoji }, set: { emoji = $0 }),
            region: face,
            onToggleInclusion: {},
            onDelete: {},
            onApplyToAll: {},
            onShapeChange: { _ in }
        )
        .environment(store)

        host(view, size: CGSize(width: 390, height: 560))
        #expect(sizeMultiplier == 1.4)
        #expect(emoji == "🐱")
    }

    @Test("AdjustmentSlidersView hosts the legacy no-region layout")
    func adjustmentSlidersWithoutRegion() {
        var intensity = 0.5
        var sizeMultiplier = 1.0
        var color = Color.appPrimary
        var emoji = "😎"

        let view = AdjustmentSlidersView(
            intensity: Binding(get: { intensity }, set: { intensity = $0 }),
            sizeMultiplier: Binding(get: { sizeMultiplier }, set: { sizeMultiplier = $0 }),
            selectedStyle: .blurredGlass,
            solidCleanColor: Binding(get: { color }, set: { color = $0 }),
            selectedEmoji: Binding(get: { emoji }, set: { emoji = $0 })
        )
        .environment(store)

        host(view, size: CGSize(width: 390, height: 360))
    }

    // MARK: - EditorView

    @Test("EditorView hosts a reviewed model with a selected manual region")
    func editorViewReviewedWithSelection() {
        let regions = manualShapeSet()
        let viewModel = makeViewModel(regions: regions, selected: regions[1].id)
        viewModel.defaultStyle = .solidClean
        viewModel.defaultShape = .circle
        viewModel.draftRevision = 3

        host(EditorView(viewModels: [viewModel]).environment(store))

        #expect(viewModel.regions.count == 4)
        #expect(viewModel.isAdjustmentPanelVisible)
    }

    @Test("EditorView hosts a selected detected face")
    func editorViewSelectedFace() {
        let regions = manualShapeSet()
        let viewModel = makeViewModel(regions: regions, selected: regions[0].id)

        host(EditorView(viewModels: [viewModel]).environment(store))
        #expect(viewModel.selectedRegion?.isFace == true)
    }

    @Test("EditorView hosts multiple images and page indicators")
    func editorViewMultipleImages() {
        let firstRegions = manualShapeSet()
        let first = makeViewModel(regions: firstRegions, selected: firstRegions[1].id)
        let second = makeViewModel()

        host(EditorView(viewModels: [first, second]).environment(store))
        #expect(first.includedRegionCount == 3)
        #expect(second.includedRegionCount == 0)
    }

    @Test("EditorView hosts no-face and detection-failure recovery states")
    func editorViewRecoveryStates() {
        let noFace = makeViewModel()
        host(EditorView(viewModels: [noFace]).environment(store))

        let failed = makeViewModel(detectionFailed: true)
        host(EditorView(viewModels: [failed]).environment(store))

        #expect(noFace.regions.isEmpty)
        #expect(failed.detectionFailed)
    }

    @Test("EditorView hosts draw mode with the full-canvas overlay")
    func editorViewDrawing() {
        let regions = manualShapeSet()
        let viewModel = makeViewModel(regions: regions, selected: nil, phase: .drawing)
        viewModel.defaultShape = .ellipse

        host(EditorView(viewModels: [viewModel]).environment(store))
        #expect(viewModel.phase == .drawing)
    }

    @Test("EditorView hosts a rendering-phase model")
    func editorViewRenderingPhase() {
        let regions = manualShapeSet()
        let viewModel = makeViewModel(regions: regions, selected: regions[0].id, phase: .rendering)

        host(EditorView(viewModels: [viewModel]).environment(store))
        #expect(viewModel.phase == .rendering)
    }

    // MARK: - ExportView

    @Test("ExportView hosts zero and multi-image region counts")
    func exportViewRegionCounts() {
        let image = makeImage()

        host(
            ExportView(originalImages: [image], maskedImages: [image], regionCounts: [0])
                .environment(store)
        )
        host(
            ExportView(
                originalImages: [image, image],
                maskedImages: [image, image],
                regionCounts: [0, 2]
            )
            .environment(store)
        )
    }
}
