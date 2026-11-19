//
//  EditorViewModel.swift
//  image-incognito
//
//  Presentation – "1/2 Choose what to hide" editor state.
//  Detected faces are proposals, not commits. All masking is explicit and is
//  only baked into pixels by `confirm(allowEmpty:)`.
//

import SwiftUI
import Observation

// MARK: - Confirm errors

enum EditorConfirmError: Error, Equatable {
    /// No included regions and the caller did not explicitly allow an empty export.
    case empty
}

// MARK: - EditorViewModel

@MainActor
@Observable
final class EditorViewModel {

    // MARK: - Phase

    enum Phase: Sendable, Equatable {
        case analyzing
        case reviewing
        case drawing
        case regionSelected
        case rendering
    }

    /// Result of a draw gesture commit.
    enum AddRegionResult: Sendable, Equatable {
        case added
        case tooSmall
        case limitReached
        case unavailable
    }

    // MARK: - Source

    let sourceImage: UIImage

    // MARK: - Region state

    var regions: [MaskRegion] = []
    var selectedRegionID: UUID?
    var phase: Phase = .analyzing
    var isAdjustmentPanelVisible = false
    /// True while the user drags a manual region. Used to freeze the pager.
    var isRegionGestureActive = false
    var detectionFailed = false

    // MARK: - Defaults for new regions

    var defaultStyle: MaskingStyle = .blurredGlass
    var defaultShape: MaskRegion.Shape = .rectangle
    var solidCleanColor: Color = .appPrimary {
        didSet {
            guard solidCleanColor != oldValue else { return }
            draftRevision += 1
        }
    }

    // MARK: - Draft / render cache

    /// Increments on every user mutation. Detection does not increment it.
    var draftRevision = 0
    /// The draft revision that produced `renderedImage`.
    var renderedRevision: Int?
    var renderedImage: UIImage?

    // MARK: - Derived state

    var isDetecting: Bool { phase == .analyzing }
    var detectionCompleted: Bool { phase != .analyzing }
    var isDrawing: Bool { phase == .drawing }

    var selectedRegion: MaskRegion? {
        guard let selectedRegionID else { return nil }
        return regions.first { $0.id == selectedRegionID }
    }

    var includedRegionCount: Int { regions.filter(\.isIncluded).count }
    var hasIncludedRegions: Bool { includedRegionCount > 0 }
    var manualRegionCount: Int { regions.filter(\.isManual).count }
    var hasDrafts: Bool { draftRevision > 0 }

    var selectedStyle: MaskingStyle { selectedRegion?.style ?? defaultStyle }

    // MARK: - Selected-region proxies

    var intensity: Double {
        get { selectedRegion?.intensity ?? 0.75 }
        set {
            guard let index = selectedIndex else { return }
            regions[index].intensity = newValue
            draftRevision += 1
        }
    }

    var sizeMultiplier: Double {
        get { selectedRegion?.sizeMultiplier ?? 1.0 }
        set {
            guard let index = selectedIndex, regions[index].isFace else { return }
            regions[index].sizeMultiplier = newValue
            draftRevision += 1
        }
    }

    var selectedEmoji: String {
        get { selectedRegion?.selectedEmoji ?? "😎" }
        set {
            guard let index = selectedIndex else { return }
            regions[index].selectedEmoji = newValue
            draftRevision += 1
        }
    }

    /// Shape of the selected manual region. Setting it switches that region's
    /// shape; with no manual selection it only updates the drawing default.
    var shape: MaskRegion.Shape {
        get { selectedRegion?.shape ?? defaultShape }
        set {
            if let region = selectedRegion, region.isManual {
                switchShape(id: region.id, to: newValue)
            } else {
                defaultShape = newValue
            }
        }
    }

    // MARK: - Use Cases

    private let detectFacesUseCase: DetectFacesUseCase
    private let renderMaskUseCase: RenderMaskUseCase

    private var selectedIndex: Int? {
        guard let selectedRegionID else { return nil }
        return regions.firstIndex { $0.id == selectedRegionID }
    }

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

    // MARK: - Detection

    /// Runs detection exactly once. Results are proposals: included by default
    /// but never rendered until `confirm(allowEmpty:)`.
    func detectFaces() async {
        guard phase == .analyzing else { return }

        do {
            let detected = try await detectFacesUseCase.execute(image: sourceImage)
            regions = detected.map { face in
                MaskRegion(
                    id: face.id,
                    source: .detectedFace,
                    shape: .ellipse,
                    rect: face.rect,
                    isIncluded: true,
                    style: defaultStyle,
                    linkedFaceID: face.id
                )
            }
            selectedRegionID = regions.first?.id
        } catch {
            detectionFailed = true
            regions = []
            selectedRegionID = nil
        }

        phase = .reviewing
    }

    // MARK: - Selection & inclusion

    /// Toggles inclusion, selects the region, and opens the adjustment panel.
    func toggleInclusion(id: UUID) {
        guard let index = regions.firstIndex(where: { $0.id == id }),
              phase != .rendering else { return }

        AppHaptics.medium()
        regions[index].isIncluded.toggle()
        selectedRegionID = id
        isAdjustmentPanelVisible = true
        phase = .regionSelected
        draftRevision += 1
    }

    func selectRegion(id: UUID?) {
        guard phase != .rendering else { return }

        guard let id else {
            selectedRegionID = nil
            isAdjustmentPanelVisible = false
            phase = .reviewing
            return
        }

        guard regions.contains(where: { $0.id == id }) else { return }

        if selectedRegionID != id {
            AppHaptics.selection()
        }
        selectedRegionID = id
        isAdjustmentPanelVisible = true
        phase = .regionSelected
    }

    // MARK: - Drawing

    func beginDrawing() {
        guard phase != .rendering, regions.count < 50 else { return }
        selectedRegionID = nil
        isAdjustmentPanelVisible = false
        phase = .drawing
    }

    func cancelDrawing() {
        guard phase == .drawing else { return }
        phase = .reviewing
    }

    /// Adds a user-drawn region. Returns the reason when the rect is too small,
    /// the region cap has been reached, or the editor is rendering.
    @discardableResult
    func addManualRegion(normalizedRect: CGRect, shape: MaskRegion.Shape) -> AddRegionResult {
        guard phase != .rendering else { return .unavailable }
        guard regions.count < 50 else { return .limitReached }

        let rect = RegionGeometry.convert(normalizedRect, to: shape)
        guard RegionGeometry.isAtLeastMinimumSize(rect) else { return .tooSmall }

        let region = MaskRegion(
            source: .manual,
            shape: shape,
            rect: rect,
            isIncluded: true,
            style: defaultStyle
        )
        regions.append(region)
        selectedRegionID = region.id
        defaultShape = shape
        isAdjustmentPanelVisible = true
        phase = .regionSelected
        draftRevision += 1
        AppHaptics.medium()
        return .added
    }

    // MARK: - Direct manipulation

    /// Moves a manual region to an absolute normalized rect.
    @discardableResult
    func moveRegion(id: UUID, to rect: CGRect) -> Bool {
        updateManualRect(id: id, to: rect)
    }

    /// Resizes a manual region to an absolute normalized rect.
    @discardableResult
    func resizeRegion(id: UUID, to rect: CGRect) -> Bool {
        updateManualRect(id: id, to: rect)
    }

    /// Switches a manual region's shape while preserving its center.
    @discardableResult
    func switchShape(id: UUID, to shape: MaskRegion.Shape) -> Bool {
        guard let index = regions.firstIndex(where: { $0.id == id }),
              regions[index].isManual,
              regions[index].shape != shape,
              phase != .rendering else { return false }

        regions[index].shape = shape
        selectedRegionID = id
        defaultShape = shape
        isAdjustmentPanelVisible = true
        phase = .regionSelected
        draftRevision += 1
        return true
    }

    func deleteRegion(id: UUID) {
        guard let index = regions.firstIndex(where: { $0.id == id }),
              phase != .rendering else { return }

        AppHaptics.medium()
        regions.remove(at: index)
        if selectedRegionID == id {
            selectedRegionID = nil
            isAdjustmentPanelVisible = false
            phase = .reviewing
        }
        draftRevision += 1
    }

    // MARK: - Styles

    func applyStyle(_ style: MaskingStyle, to id: UUID) {
        guard let index = regions.firstIndex(where: { $0.id == id }),
              phase != .rendering else { return }

        AppHaptics.selection()
        regions[index].style = style
        defaultStyle = style
        selectedRegionID = id
        draftRevision += 1
    }

    /// Copies style and emoji (not intensity) to every included region.
    func applyStyleToAll(_ style: MaskingStyle) {
        guard phase != .rendering else { return }

        let emoji = selectedRegion?.selectedEmoji ?? "😎"
        for index in regions.indices where regions[index].isIncluded {
            regions[index].style = style
            regions[index].selectedEmoji = emoji
        }
        defaultStyle = style
        draftRevision += 1
        AppHaptics.selection()
    }

    // MARK: - Confirm / render

    /// Bakes the current draft into pixels.
    ///
    /// - Throws: `EditorConfirmError.empty` when nothing is included and the
    ///   caller did not opt into an explicit original export.
    /// - Throws: the renderer error unchanged. There is no silent fallback.
    func confirm(allowEmpty: Bool) async throws -> UIImage {
        let included = regions.filter(\.isIncluded)

        if included.isEmpty {
            guard allowEmpty else { throw EditorConfirmError.empty }
            // Explicit "export the original" override — no rendering.
            return sourceImage
        }

        if renderedRevision == draftRevision, let renderedImage {
            return renderedImage
        }

        let revision = draftRevision
        phase = .rendering

        do {
            let result = try await renderMaskUseCase.execute(
                image: sourceImage,
                regions: included,
                solidCleanColor: UIColor(solidCleanColor)
            )
            renderedImage = result
            renderedRevision = revision
            phase = .reviewing
            return result
        } catch {
            phase = .reviewing
            throw error
        }
    }

    // MARK: - Private

    /// Applies a clamped absolute rect to a manual region, rejecting sizes below
    /// the minimum and keeping circles 1:1 via `RegionGeometry`.
    private func updateManualRect(id: UUID, to rect: CGRect) -> Bool {
        guard let index = regions.firstIndex(where: { $0.id == id }),
              regions[index].isManual,
              phase != .rendering else { return false }

        let converted = RegionGeometry.convert(rect, to: regions[index].shape)
        guard RegionGeometry.isAtLeastMinimumSize(converted) else { return false }

        regions[index].rect = converted
        selectedRegionID = id
        draftRevision += 1
        return true
    }
}
