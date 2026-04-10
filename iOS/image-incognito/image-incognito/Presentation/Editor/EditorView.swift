//
//  EditorView.swift
//  image-incognito
//
//  Screen 2 – AI Editor (Core Experience)
//  Face detection results + masking style selection workspace.
//

import SwiftUI

struct EditorView: View {

    @State private var viewModels: [EditorViewModel]
    @State private var currentIndex: Int = 0
    @State private var allRenderedImages: [UIImage]? = nil
    @State private var isExporting: Bool = false
    @Environment(\.dismiss) private var dismiss

    init(images: [UIImage]) {
        _viewModels = State(initialValue: images.map { EditorViewModel(sourceImage: $0) })
    }

    private var currentVM: EditorViewModel { viewModels[currentIndex] }

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

                if viewModels.count > 1 {
                    pageIndicator
                        .padding(.vertical, Spacing.xSmall)
                }

                buildBottomSection(for: currentVM)
                    .padding(.bottom, Spacing.large)
                    .animation(AppAnimation.standard, value: currentVM.showAdjustmentSliders)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await withTaskGroup(of: Void.self) { group in
                for vm in viewModels {
                    group.addTask { try? await vm.detectFaces() }
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
                ExportView(maskedImages: images)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                AppHaptics.light()
                dismiss()
            } label: {
                HStack(spacing: Spacing.xxSmall) {
                    Image(systemName: "chevron.left")
                        .imageScale(.medium)
                        .fontWeight(.semibold)
                    Text("취소")
                        .font(.appBody)
                }
                .foregroundStyle(Color.appLabelSecondary)
            }

            Spacer()

            if currentVM.isDetecting {
                HStack(spacing: Spacing.xSmall) {
                    ProgressView()
                        .tint(Color.appPrimary)
                        .scaleEffect(0.8)
                    Text("인물 찾는 중...")
                        .font(.appFootnote)
                        .foregroundStyle(Color.appLabelSecondary)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else {
                HStack(spacing: Spacing.xSmall) {
                    if viewModels.count > 1 {
                        Text("\(currentIndex + 1)/\(viewModels.count)")
                            .font(.appFootnote)
                            .foregroundStyle(Color.appLabelTertiary)
                    }
                    if !currentVM.faces.isEmpty {
                        Text("\(currentVM.faces.count)명 감지됨")
                            .font(.appFootnote)
                            .foregroundStyle(Color.appLabelTertiary)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            Spacer()

            Button {
                Task { await exportAll() }
            } label: {
                HStack(spacing: Spacing.xxSmall) {
                    if isExporting {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.75)
                    }
                    Text(isExporting ? "준비 중..." : "내보내기")
                        .font(.appBodyEmphasized)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.xSmall)
                .background(Color.appPrimary.opacity(isExporting ? 0.6 : 1))
                .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
                .animation(AppAnimation.snappy, value: isExporting)
            }
            .disabled(isExporting)
        }
        .animation(AppAnimation.snappy, value: currentVM.isDetecting)
        .animation(AppAnimation.snappy, value: currentVM.faces.count)
    }

    // MARK: - Image Carousel

    private var imageCarousel: some View {
        TabView(selection: $currentIndex) {
            ForEach(viewModels.indices, id: \.self) { index in
                imageCanvas(for: viewModels[index])
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(viewModels.indices, id: \.self) { index in
                Capsule()
                    .fill(index == currentIndex ? Color.appPrimary : Color.appLabelTertiary.opacity(0.4))
                    .frame(width: index == currentIndex ? 16 : 6, height: 6)
                    .animation(AppAnimation.snappy, value: currentIndex)
            }
        }
    }

    // MARK: - Image Canvas

    private func imageCanvas(for vm: EditorViewModel) -> some View {
        GeometryReader { proxy in
            let imgRect = imageRenderRect(
                in: proxy.size,
                imageSize: CGSize(
                    width: vm.sourceImage.size.width,
                    height: vm.sourceImage.size.height
                )
            )

            ZStack {
                // Source image
                Image(uiImage: vm.sourceImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Face overlays
                ForEach(vm.faces) { face in
                    let frame = overlayFrame(for: face, imageRect: imgRect, sizeMultiplier: vm.sizeMultiplier)
                    FaceOverlayView(
                        faceBox: face,
                        intensity: vm.intensity,
                        sizeMultiplier: vm.sizeMultiplier,
                        solidCleanColor: vm.solidCleanColor
                    )
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
                    // Without this, the stroke-only border (isMasked=false) has no filled
                    // hit area and taps fall through to the image underneath, preventing
                    // the user from re-enabling a mask.
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(AppAnimation.snappy) {
                            vm.toggleMask(id: face.id)
                        }
                    }
                }

                // Loading skeleton
                if vm.isDetecting {
                    DetectingSkeletonView()
                        .transition(.opacity)
                }

                // Empty state when no faces found after detection
                if !vm.isDetecting && vm.faces.isEmpty {
                    NoFaceFoundView()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
        .clipped()
    }

    // MARK: - Bottom Section

    @ViewBuilder
    private func buildBottomSection(for vm: EditorViewModel) -> some View {
        @Bindable var vm = vm
        VStack(spacing: Spacing.medium) {
            if vm.showAdjustmentSliders {
                AdjustmentSlidersView(
                    intensity: $vm.intensity,
                    sizeMultiplier: $vm.sizeMultiplier,
                    selectedStyle: vm.selectedStyle,
                    solidCleanColor: $vm.solidCleanColor
                )
                .padding(.horizontal, Spacing.large)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            GlassmorphismToolbar {
                HStack(spacing: Spacing.xxLarge) {
                    ForEach(MaskingStyle.allCases) { style in
                        StylePill(
                            icon: style.icon,
                            label: style.label,
                            isSelected: vm.selectedStyle == style
                        ) {
                            vm.selectStyle(style)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Export

    private func exportAll() async {
        guard !isExporting else { return }
        AppHaptics.medium()
        isExporting = true

        var results: [UIImage] = []
        for vm in viewModels {
            let image = await vm.renderImage()
            results.append(image)
        }

        isExporting = false
        allRenderedImages = results
    }

    // MARK: - Layout Helpers

    /// Calculates the rendered CGRect of a `.scaledToFit` image inside `containerSize`.
    private func imageRenderRect(in containerSize: CGSize, imageSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return CGRect(origin: .zero, size: containerSize)
        }
        let containerAspect = containerSize.width / containerSize.height
        let imageAspect = imageSize.width / imageSize.height

        let renderSize: CGSize
        if imageAspect > containerAspect {
            let w = containerSize.width
            renderSize = CGSize(width: w, height: w / imageAspect)
        } else {
            let h = containerSize.height
            renderSize = CGSize(width: h * imageAspect, height: h)
        }

        return CGRect(
            x: (containerSize.width - renderSize.width) / 2,
            y: (containerSize.height - renderSize.height) / 2,
            width: renderSize.width,
            height: renderSize.height
        )
    }

    /// Maps a normalized FaceBox rect to an absolute CGRect within `imageRect`,
    /// scaled by `sizeMultiplier` about the face center.
    private func overlayFrame(for face: FaceBox, imageRect: CGRect, sizeMultiplier: Double) -> CGRect {
        let base = CGRect(
            x: imageRect.minX + face.rect.minX * imageRect.width,
            y: imageRect.minY + face.rect.minY * imageRect.height,
            width: face.rect.width * imageRect.width,
            height: face.rect.height * imageRect.height
        )
        guard face.isMasked else { return base }

        // Apply sizeMultiplier centered on the face
        let scale = sizeMultiplier
        let newWidth = base.width * scale
        let newHeight = base.height * scale
        return CGRect(
            x: base.midX - newWidth / 2,
            y: base.midY - newHeight / 2,
            width: newWidth,
            height: newHeight
        )
    }
}

// MARK: - Preview

#Preview("AI Editor – with sample faces") {
    NavigationStack {
        EditorView(images: [previewImage(), previewImage()])
    }
}

#Preview("AI Editor – Dark Mode") {
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

        // Simulate a face-shaped area
        UIColor.systemGray3.setFill()
        let faceRect = CGRect(x: 130, y: 180, width: 140, height: 160)
        UIBezierPath(ovalIn: faceRect).fill()
    }
}
