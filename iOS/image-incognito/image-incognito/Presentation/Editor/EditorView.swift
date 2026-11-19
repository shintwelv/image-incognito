//
//  EditorView.swift
//  image-incognito
//
//  Screen 2 – "1/2 Choose what to hide" review workspace.
//  Detection results are suggestions. The user includes/excludes proposals,
//  draws manual rectangles/circles/ellipses, and only `confirm` bakes pixels.
//

import SwiftUI

struct EditorView: View {

    @State private var viewModels: [EditorViewModel]
    @State private var currentIndex: Int = 0
    @State private var allRenderedImages: [UIImage]?
    @State private var renderedRegionCounts: [Int] = []
    @State private var isShowingRegionList = false
    @State private var activeAlert: EditorAlert?
    @State private var renderProgress: (current: Int, total: Int)?
    @State private var lastRenderAllowEmptyIndices: [Int] = []
    @State private var lastRenderAllowEmptyAll = false
    @State private var toastMessage = ""
    @State private var showToast = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(images: [UIImage]) {
        _viewModels = State(initialValue: images.map { EditorViewModel(sourceImage: $0) })
    }

    /// Test/composition injection: use prebuilt view models (phases, regions,
    /// and selection preserved).
    init(viewModels: [EditorViewModel]) {
        _viewModels = State(initialValue: viewModels)
    }

    // MARK: - Derived state

    private var currentVM: EditorViewModel { viewModels[currentIndex] }
    private var totalIncludedCount: Int { viewModels.reduce(0) { $0 + $1.includedRegionCount } }
    private var isAnyAnalyzing: Bool { viewModels.contains { $0.phase == .analyzing } }
    private var isAnyRendering: Bool { viewModels.contains { $0.phase == .rendering } }
    private var isConfirmDisabled: Bool { isAnyAnalyzing || isAnyRendering || renderProgress != nil }
    private var isPagingLocked: Bool {
        renderProgress != nil
            || currentVM.phase == .drawing
            || currentVM.phase == .rendering
            || currentVM.isRegionGestureActive
    }

    private var hasDrafts: Bool { viewModels.contains(where: \.hasDrafts) }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, Spacing.medium)
                    .padding(.top, Spacing.small)
                    .padding(.bottom, Spacing.xSmall)

                imageCarousel
                    .layoutPriority(1)

                if viewModels.count > 1 && currentVM.phase != .drawing {
                    pageIndicator
                        .padding(.vertical, Spacing.xSmall)
                }

                bottomSection(for: currentVM)
                    .padding(.bottom, Spacing.large)
                    .animation(
                        reduceMotion ? nil : AppAnimation.standard,
                        value: currentVM.isAdjustmentPanelVisible
                    )
            }

            if let renderProgress {
                RenderingOverlayView(current: renderProgress.current, total: renderProgress.total)
                    .transition(.opacity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await withTaskGroup(of: Void.self) { group in
                for viewModel in viewModels {
                    group.addTask { await viewModel.detectFaces() }
                }
            }
        }
        .navigationDestination(
            isPresented: Binding(
                get: { allRenderedImages != nil },
                set: { if !$0 { allRenderedImages = nil } }
            )
        ) {
            if let images = allRenderedImages {
                ExportView(
                    originalImages: viewModels.map(\.sourceImage),
                    maskedImages: images,
                    regionCounts: renderedRegionCounts
                )
            }
        }
        .sheet(isPresented: $isShowingRegionList) {
            RegionListView(viewModel: currentVM) {
                isShowingRegionList = false
            }
        }
        .alert(item: $activeAlert) { alert in
            alertContent(for: alert)
        }
        .appToast(isPresented: $showToast, message: toastMessage)
        .background(
            InteractivePopGestureController(isEnabled: !hasDrafts)
                .frame(width: 0, height: 0)
                .accessibilityHidden(true)
        )
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: Spacing.xSmall) {
            Button {
                handleBackTapped()
            } label: {
                Image(systemName: "chevron.left")
                    .imageScale(.medium)
                    .fontWeight(.semibold)
                    .frame(width: 44, height: 44)
                    .foregroundStyle(Color.appLabelSecondary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("editor.cancel")
            .accessibilityIdentifier("editor.cancelButton")

            VStack(alignment: .leading, spacing: 0) {
                Text("editor.review.title")
                    .font(.appBodyEmphasized)
                    .foregroundStyle(Color.appLabelPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                HStack(spacing: Spacing.xSmall) {
                    Text("\(currentIndex + 1)/\(viewModels.count)")
                        .font(.appCaption)
                        .foregroundStyle(Color.appLabelTertiary)
                        .monospacedDigit()
                        .accessibilityIdentifier("editor.imageCounter")

                    if currentVM.detectionCompleted {
                        HStack(spacing: 2) {
                            Image(systemName: "shield.lefthalf.filled")
                                .imageScale(.small)
                            Text("\(currentVM.includedRegionCount)")
                                .monospacedDigit()
                        }
                        .font(.appCaption)
                        .foregroundStyle(Color.appLabelSecondary)
                        .accessibilityLabel(
                            Text(
                                String(
                                    format: NSLocalizedString("editor.pageIndicator.accessibility", comment: ""),
                                    currentIndex + 1,
                                    currentVM.includedRegionCount
                                )
                            )
                        )
                        .accessibilityIdentifier("editor.includedCount")
                    }
                }
            }

            Spacer(minLength: Spacing.xSmall)

            Button {
                AppHaptics.light()
                isShowingRegionList = true
            } label: {
                Image(systemName: "list.bullet")
                    .imageScale(.medium)
                    .frame(width: 44, height: 44)
                    .foregroundStyle(Color.appPrimary)
                    .background(Color.appPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: Radius.element, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("editor.regionList.title")
            .accessibilityIdentifier("editor.listButton")

            confirmButton
        }
        .animation(reduceMotion ? nil : AppAnimation.snappy, value: currentVM.detectionCompleted)
        .animation(reduceMotion ? nil : AppAnimation.snappy, value: totalIncludedCount)
    }

    private var confirmButton: some View {
        Button {
            Task { await confirmTapped() }
        } label: {
            HStack(spacing: Spacing.xxSmall) {
                if renderProgress != nil || isAnyRendering {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.7)
                }
                Text(confirmTitle)
                    .font(.appFootnote)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .monospacedDigit()
            }
            .padding(.horizontal, Spacing.small)
            .frame(minHeight: 44)
            .background(Color.appPrimary.opacity(isConfirmDisabled ? 0.45 : 1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isConfirmDisabled)
        .accessibilityIdentifier("editor.confirmButton")
    }

    private var confirmTitle: String {
        if isAnyAnalyzing {
            return NSLocalizedString("editor.review.analyzingAll", comment: "")
        }
        if isAnyRendering || renderProgress != nil {
            return NSLocalizedString("editor.rendering.short", comment: "")
        }
        if viewModels.count > 1 {
            return String(
                format: NSLocalizedString("editor.confirm.multi", comment: ""),
                totalIncludedCount,
                viewModels.count
            )
        }
        return String(
            format: NSLocalizedString("editor.confirm", comment: ""),
            totalIncludedCount
        )
    }

    // MARK: - Carousel

    private var currentIndexBinding: Binding<Int?> {
        Binding(
            get: { currentIndex },
            set: { if let newIndex = $0 { currentIndex = newIndex } }
        )
    }

    private var imageCarousel: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(viewModels.indices, id: \.self) { index in
                    imageCanvas(for: viewModels[index])
                        .containerRelativeFrame([.horizontal, .vertical])
                        .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: currentIndexBinding)
        .scrollIndicators(.hidden)
        .scrollDisabled(isPagingLocked)
        .accessibilityIdentifier("editor.imageCarousel")
    }

    // MARK: - Page indicator

    private var pageIndicator: some View {
        HStack(spacing: Spacing.xSmall) {
            ForEach(viewModels.indices, id: \.self) { index in
                let count = viewModels[index].includedRegionCount
                let isCurrent = index == currentIndex

                Button {
                    withAnimation(reduceMotion ? nil : AppAnimation.snappy) {
                        currentIndex = index
                    }
                } label: {
                    Text(count > 0 ? "\(count)" : "!")
                        .font(.appCaption2)
                        .monospacedDigit()
                        .foregroundStyle(
                            count == 0
                                ? Color.appDestructive
                                : (isCurrent ? Color.appPrimary : Color.appLabelSecondary)
                        )
                        .padding(.horizontal, Spacing.xSmall)
                        .frame(minWidth: 32, minHeight: 32)
                        .background(
                            Capsule()
                                .fill(
                                    count == 0
                                        ? Color.appDestructive.opacity(0.12)
                                        : (isCurrent ? Color.appPrimary.opacity(0.16) : Color.appLabelTertiary.opacity(0.12))
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(isCurrent ? Color.appPrimary : Color.clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    Text(
                        String(
                            format: NSLocalizedString("editor.pageIndicator.accessibility", comment: ""),
                            index + 1,
                            count
                        )
                    )
                )
                .accessibilityIdentifier("editor.pageDot.\(index)")
            }
        }
        .accessibilityIdentifier("editor.pageIndicator")
        .animation(reduceMotion ? nil : AppAnimation.snappy, value: currentIndex)
    }

    // MARK: - Canvas

    private func imageCanvas(for viewModel: EditorViewModel) -> some View {
        GeometryReader { proxy in
            let imageRect = RegionHitTester.imageRenderRect(
                in: proxy.size,
                imageSize: viewModel.sourceImage.size
            )

            ZStack {
                Image(uiImage: viewModel.sourceImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Empty-canvas tap target, below the region overlays.
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard viewModel.phase != .drawing, viewModel.phase != .rendering else { return }
                        viewModel.selectRegion(id: nil)
                    }

                ForEach(viewModel.regions) { region in
                    let frame = RegionHitTester.overlayFrame(for: region, imageRect: imageRect)
                    RegionOverlayView(
                        region: region,
                        solidCleanColor: viewModel.solidCleanColor,
                        isSelected: region.id == viewModel.selectedRegionID,
                        canvasSize: imageRect.size,
                        onToggleInclusion: {
                            viewModel.toggleInclusion(id: region.id)
                        },
                        onMove: { rect in
                            viewModel.moveRegion(id: region.id, to: rect)
                        },
                        onResize: { rect in
                            viewModel.resizeRegion(id: region.id, to: rect)
                        },
                        onGestureActiveChange: { isActive in
                            viewModel.isRegionGestureActive = isActive
                        }
                    )
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
                    .allowsHitTesting(viewModel.phase != .drawing && viewModel.phase != .rendering)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(Text(regionAccessibilityLabel(region)))
                    .accessibilityValue(
                        Text(
                            region.id == viewModel.selectedRegionID
                                ? NSLocalizedString("editor.region.selected", comment: "")
                                : ""
                        )
                    )
                    .accessibilityIdentifier("editor.regionOverlay.\(region.id.uuidString)")
                    .accessibilityAction(
                        named: Text(
                            NSLocalizedString(
                                region.isIncluded ? "editor.region.exclude" : "editor.region.include",
                                comment: ""
                            )
                        )
                    ) {
                        viewModel.toggleInclusion(id: region.id)
                    }
                    .accessibilityAction(
                        named: Text(NSLocalizedString("editor.region.delete", comment: ""))
                    ) {
                        viewModel.deleteRegion(id: region.id)
                    }
                }

                if viewModel.isDetecting {
                    DetectingSkeletonView()
                        .transition(.opacity)
                } else if viewModel.detectionCompleted {
                    if viewModel.detectionFailed && viewModel.regions.isEmpty {
                        DetectionFailedView {
                            viewModel.beginDrawing()
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else if viewModel.regions.isEmpty {
                        NoFaceFoundView {
                            viewModel.beginDrawing()
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }

                if viewModel.phase == .drawing {
                    DrawRegionOverlay(
                        imageRect: imageRect,
                        selectedShape: viewModel.defaultShape,
                        onShapeChange: { viewModel.defaultShape = $0 },
                        onCancel: { viewModel.cancelDrawing() },
                        onCommit: { rect in
                            switch viewModel.addManualRegion(
                                normalizedRect: rect,
                                shape: viewModel.defaultShape
                            ) {
                            case .added:
                                break
                            case .tooSmall:
                                showToastMessage(NSLocalizedString("editor.draw.tooSmall", comment: ""))
                            case .limitReached:
                                showToastMessage(NSLocalizedString("editor.regionLimit.reached", comment: ""))
                            case .unavailable:
                                break
                            }
                        }
                    )
                    .transition(.opacity)
                }
            }
            .animation(reduceMotion ? nil : AppAnimation.snappy, value: viewModel.phase)
        }
        .clipped()
    }

    // MARK: - Bottom section

    @ViewBuilder
    private func bottomSection(for viewModel: EditorViewModel) -> some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: Spacing.small) {
            if viewModel.isAdjustmentPanelVisible, let region = viewModel.selectedRegion {
                ScrollView(.vertical, showsIndicators: false) {
                    AdjustmentSlidersView(
                        intensity: $viewModel.intensity,
                        sizeMultiplier: $viewModel.sizeMultiplier,
                        selectedStyle: viewModel.selectedStyle,
                        solidCleanColor: $viewModel.solidCleanColor,
                        selectedEmoji: $viewModel.selectedEmoji,
                        region: region,
                        onToggleInclusion: {
                            viewModel.toggleInclusion(id: region.id)
                        },
                        onDelete: {
                            viewModel.deleteRegion(id: region.id)
                            showToastMessage(NSLocalizedString("editor.region.deleteToast", comment: ""))
                        },
                        onApplyToAll: {
                            viewModel.applyStyleToAll(viewModel.selectedStyle)
                            showToastMessage(NSLocalizedString("editor.style.appliedToAll", comment: ""))
                        },
                        onShapeChange: { shape in
                            viewModel.switchShape(id: region.id, to: shape)
                        }
                    )
                }
                .frame(maxHeight: 360)
                .padding(.horizontal, Spacing.large)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            addRegionButton(for: viewModel)
                .padding(.horizontal, Spacing.large)

            styleToolbar(for: viewModel)
        }
    }

    private func addRegionButton(for viewModel: EditorViewModel) -> some View {
        Button {
            AppHaptics.light()
            viewModel.beginDrawing()
        } label: {
            HStack(spacing: Spacing.xSmall) {
                Image(systemName: "plus.viewfinder")
                    .imageScale(.medium)
                Text("editor.addRegion")
                    .font(.appBodyEmphasized)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .padding(.vertical, Spacing.xSmall)
            .background(Color.appPrimary.opacity(0.12))
            .foregroundStyle(Color.appPrimary)
            .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.phase == .drawing || viewModel.phase == .rendering || viewModel.regions.count >= 50)
        .opacity(viewModel.regions.count >= 50 ? 0.45 : 1)
        .accessibilityIdentifier("editor.addRegion")
    }

    private func styleToolbar(for viewModel: EditorViewModel) -> some View {
        GlassmorphismToolbar {
            VStack(spacing: Spacing.xSmall) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.medium) {
                        ForEach(MaskingStyle.allCases) { style in
                            StylePill(
                                icon: style.icon,
                                label: style.label,
                                isSelected: viewModel.selectedRegion != nil && viewModel.selectedStyle == style
                            ) {
                                guard let id = viewModel.selectedRegionID else { return }
                                viewModel.applyStyle(style, to: id)
                            }
                            .disabled(viewModel.selectedRegionID == nil)
                            .opacity(viewModel.selectedRegionID == nil ? 0.45 : 1)
                            .frame(minWidth: 44, minHeight: 44)
                            .accessibilityIdentifier("editor.stylePill.\(style.rawValue)")
                        }
                    }
                }

                if viewModel.selectedRegionID == nil {
                    Text("editor.style.selectRegionFirst")
                        .font(.appCaption)
                        .foregroundStyle(Color.appLabelTertiary)
                        .accessibilityIdentifier("editor.styleHint")
                }
            }
        }
    }

    // MARK: - Back

    private func handleBackTapped() {
        if hasDrafts {
            activeAlert = .discard
        } else {
            AppHaptics.light()
            dismiss()
        }
    }

    // MARK: - Confirm / render

    private func confirmTapped() async {
        guard !isConfirmDisabled else { return }

        AppHaptics.medium()
        let counts = viewModels.map(\.includedRegionCount)
        let total = counts.reduce(0, +)

        if total == 0 {
            activeAlert = .empty
            return
        }

        let emptyIndices = counts.indices.filter { counts[$0] == 0 }
        if !emptyIndices.isEmpty {
            activeAlert = .partial(emptyIndices)
            return
        }

        await renderAll(allowEmptyIndices: [], allowEmptyAll: false)
    }

    private func renderAll(allowEmptyIndices: [Int], allowEmptyAll: Bool) async {
        guard renderProgress == nil,
              viewModels.allSatisfy({ $0.phase != .analyzing && $0.phase != .rendering }) else { return }

        lastRenderAllowEmptyIndices = allowEmptyIndices
        lastRenderAllowEmptyAll = allowEmptyAll

        var images: [UIImage] = []
        var counts: [Int] = []

        for (index, viewModel) in viewModels.enumerated() {
            renderProgress = (current: index + 1, total: viewModels.count)
            do {
                let allowEmpty = allowEmptyAll || allowEmptyIndices.contains(index)
                let image = try await viewModel.confirm(allowEmpty: allowEmpty)
                images.append(image)
                counts.append(viewModel.includedRegionCount)
            } catch {
                renderProgress = nil
                activeAlert = .renderFailure
                return
            }
        }

        renderProgress = nil
        renderedRegionCounts = counts
        allRenderedImages = images
    }

    // MARK: - Alerts

    private func alertContent(for alert: EditorAlert) -> Alert {
        switch alert {
        case .discard:
            return Alert(
                title: Text("editor.discard.title"),
                message: Text("editor.discard.message"),
                primaryButton: .destructive(Text("editor.discard.leave")) {
                    dismiss()
                },
                secondaryButton: .cancel(Text("editor.discard.keepEditing"))
            )

        case .empty:
            return Alert(
                title: Text("editor.confirmEmpty.title"),
                message: Text("editor.confirmEmpty.message"),
                primaryButton: .destructive(Text("editor.confirmEmpty.exportOriginal")) {
                    Task { await renderAll(allowEmptyIndices: [], allowEmptyAll: true) }
                },
                secondaryButton: .cancel(Text("editor.confirmEmpty.back"))
            )

        case .partial(let indices):
            return Alert(
                title: Text("editor.confirmPartial.title"),
                message: Text(partialMessage(for: indices)),
                primaryButton: .default(Text("editor.confirmPartial.continue")) {
                    Task { await renderAll(allowEmptyIndices: indices, allowEmptyAll: false) }
                },
                secondaryButton: .cancel(Text("editor.confirmEmpty.back")) {
                    if let first = indices.first {
                        currentIndex = first
                    }
                }
            )

        case .renderFailure:
            return Alert(
                title: Text("editor.rendering.failed"),
                message: nil,
                primaryButton: .default(Text("editor.rendering.retry")) {
                    Task {
                        await renderAll(
                            allowEmptyIndices: lastRenderAllowEmptyIndices,
                            allowEmptyAll: lastRenderAllowEmptyAll
                        )
                    }
                },
                secondaryButton: .cancel(Text("editor.confirmEmpty.back"))
            )
        }
    }

    private func partialMessage(for indices: [Int]) -> String {
        let numbers = indices.map { String($0 + 1) }.joined(separator: ", ")
        return String(
            format: NSLocalizedString("editor.confirmPartial.message", comment: ""),
            numbers
        )
    }

    // MARK: - Helpers

    private func showToastMessage(_ message: String) {
        toastMessage = message
        withAnimation(reduceMotion ? nil : AppAnimation.standard) {
            showToast = true
        }
    }

    private func regionAccessibilityLabel(_ region: MaskRegion) -> String {
        let type = NSLocalizedString(region.isManual ? "editor.region.manual" : "editor.region.face", comment: "")
        let status = NSLocalizedString(region.isIncluded ? "editor.region.included" : "editor.region.excluded", comment: "")
        let style = NSLocalizedString(region.style.label, comment: "")
        if region.isManual {
            let shape = NSLocalizedString(region.shape.labelKey, comment: "")
            return "\(type) · \(shape) · \(status) · \(style)"
        }
        return "\(type) · \(status) · \(style)"
    }
}

// MARK: - Alert state

private enum EditorAlert: Identifiable {
    case discard
    case empty
    case partial([Int])
    case renderFailure

    var id: String {
        switch self {
        case .discard: return "discard"
        case .empty: return "empty"
        case .partial(let indices): return "partial-\(indices.map(String.init).joined(separator: "-"))"
        case .renderFailure: return "renderFailure"
        }
    }
}

// MARK: - Preview

#Preview("Editor – Review") {
    NavigationStack {
        EditorView(images: [previewImage(), previewImage()])
    }
}

#Preview("Editor – Dark Mode") {
    NavigationStack {
        EditorView(images: [previewImage()])
    }
    .preferredColorScheme(.dark)
}

private func previewImage() -> UIImage {
    let size = CGSize(width: 400, height: 600)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { ctx in
        UIColor.systemGray5.setFill()
        ctx.fill(CGRect(origin: .zero, size: size))

        UIColor.systemGray3.setFill()
        let faceRect = CGRect(x: 130, y: 180, width: 140, height: 160)
        UIBezierPath(ovalIn: faceRect).fill()
    }
}
