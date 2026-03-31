//
//  EditorView.swift
//  image-incognito
//
//  Screen 2 – AI Editor (Core Experience)
//  Face detection results + masking style selection workspace.
//

import SwiftUI

struct EditorView: View {

    @State private var viewModel: EditorViewModel
    @Environment(\.dismiss) private var dismiss

    init(image: UIImage) {
        _viewModel = State(initialValue: EditorViewModel(sourceImage: image))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, Spacing.medium)
                    .padding(.top, Spacing.small)
                    .padding(.bottom, Spacing.xSmall)

                imageCanvas
                    .layoutPriority(1)

                bottomSection
                    .padding(.bottom, Spacing.large)
                    .animation(AppAnimation.standard, value: viewModel.showAdjustmentSliders)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            try? await viewModel.detectFaces()
        }
        // Navigate to ExportView once the masked image is ready
        .navigationDestination(
            isPresented: Binding(
                get: { viewModel.renderedImage != nil },
                set: { if !$0 { viewModel.renderedImage = nil } }
            )
        ) {
            if let image = viewModel.renderedImage {
                ExportView(maskedImage: image)
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

            if viewModel.isDetecting {
                HStack(spacing: Spacing.xSmall) {
                    ProgressView()
                        .tint(Color.appPrimary)
                        .scaleEffect(0.8)
                    Text("인물 찾는 중...")
                        .font(.appFootnote)
                        .foregroundStyle(Color.appLabelSecondary)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            } else if !viewModel.faces.isEmpty {
                Text("\(viewModel.faces.count)명 감지됨")
                    .font(.appFootnote)
                    .foregroundStyle(Color.appLabelTertiary)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }

            Spacer()

            Button {
                Task { await viewModel.exportTapped() }
            } label: {
                HStack(spacing: Spacing.xxSmall) {
                    if viewModel.isRendering {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.75)
                    }
                    Text(viewModel.isRendering ? "준비 중..." : "내보내기")
                        .font(.appBodyEmphasized)
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.xSmall)
                .background(Color.appPrimary.opacity(viewModel.isRendering ? 0.6 : 1))
                .clipShape(RoundedRectangle(cornerRadius: Radius.button, style: .continuous))
                .animation(AppAnimation.snappy, value: viewModel.isRendering)
            }
            .disabled(viewModel.isRendering)
        }
        .animation(AppAnimation.snappy, value: viewModel.isDetecting)
        .animation(AppAnimation.snappy, value: viewModel.faces.count)
    }

    // MARK: - Image Canvas

    private var imageCanvas: some View {
        GeometryReader { proxy in
            let imgRect = imageRenderRect(
                in: proxy.size,
                imageSize: CGSize(
                    width: viewModel.sourceImage.size.width,
                    height: viewModel.sourceImage.size.height
                )
            )

            ZStack {
                // Source image
                Image(uiImage: viewModel.sourceImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Face overlays
                ForEach(viewModel.faces) { face in
                    let frame = overlayFrame(for: face, imageRect: imgRect)
                    FaceOverlayView(
                        faceBox: face,
                        intensity: viewModel.intensity,
                        sizeMultiplier: viewModel.sizeMultiplier
                    )
                    .frame(width: frame.width, height: frame.height)
                    .position(x: frame.midX, y: frame.midY)
                    .onTapGesture {
                        withAnimation(AppAnimation.snappy) {
                            viewModel.toggleMask(id: face.id)
                        }
                    }
                }

                // Loading skeleton
                if viewModel.isDetecting {
                    DetectingSkeletonView()
                        .transition(.opacity)
                }

                // Empty state when no faces found after detection
                if !viewModel.isDetecting && viewModel.faces.isEmpty {
                    NoFaceFoundView()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
        .clipped()
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: Spacing.medium) {
            if viewModel.showAdjustmentSliders {
                AdjustmentSlidersView(
                    intensity: $viewModel.intensity,
                    sizeMultiplier: $viewModel.sizeMultiplier
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
                            isSelected: viewModel.selectedStyle == style
                        ) {
                            viewModel.selectStyle(style)
                        }
                    }
                }
            }
        }
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
    private func overlayFrame(for face: FaceBox, imageRect: CGRect) -> CGRect {
        let base = CGRect(
            x: imageRect.minX + face.rect.minX * imageRect.width,
            y: imageRect.minY + face.rect.minY * imageRect.height,
            width: face.rect.width * imageRect.width,
            height: face.rect.height * imageRect.height
        )
        guard face.isMasked else { return base }

        // Apply sizeMultiplier centered on the face
        let scale = viewModel.sizeMultiplier
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

// MARK: - Face Overlay View

private struct FaceOverlayView: View {
    let faceBox: FaceBox
    let intensity: Double
    let sizeMultiplier: Double

    var body: some View {
        ZStack {
            if faceBox.isMasked {
                maskLayer
            }
            borderLayer
        }
    }

    @ViewBuilder
    private var maskLayer: some View {
        switch faceBox.style {
        case .blurredGlass:
            RoundedRectangle(cornerRadius: Radius.element, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.element, style: .continuous)
                        .fill(Color.white.opacity(0.15 * intensity))
                }
                .opacity(intensity)

        case .pixelArt:
            PixelArtMaskView(intensity: intensity)

        case .solidClean:
            RoundedRectangle(cornerRadius: Radius.element, style: .continuous)
                .fill(Color.appPrimary.opacity(0.55 + 0.35 * intensity))
        }
    }

    private var borderLayer: some View {
        RoundedRectangle(cornerRadius: Radius.element, style: .continuous)
            .stroke(
                faceBox.isMasked ? Color.white.opacity(0.85) : Color.white.opacity(0.45),
                lineWidth: faceBox.isMasked ? 2 : 1.5
            )
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Pixel Art Mask View

private struct PixelArtMaskView: View {
    let intensity: Double
    private let gridCount = 8

    var body: some View {
        Canvas { context, size in
            let cellW = size.width / CGFloat(gridCount)
            let cellH = size.height / CGFloat(gridCount)
            let palette: [Color] = [
                Color(white: 0.72),
                Color(white: 0.48),
                Color(white: 0.60),
                Color(white: 0.36)
            ]

            for row in 0..<gridCount {
                for col in 0..<gridCount {
                    let rect = CGRect(
                        x: CGFloat(col) * cellW,
                        y: CGFloat(row) * cellH,
                        width: cellW,
                        height: cellH
                    )
                    let idx = ((row * 3) ^ (col * 5) + row + col) % palette.count
                    context.fill(
                        Path(rect),
                        with: .color(palette[idx].opacity(intensity))
                    )
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.element, style: .continuous))
    }
}

// MARK: - Adjustment Sliders View

private struct AdjustmentSlidersView: View {
    @Binding var intensity: Double
    @Binding var sizeMultiplier: Double

    var body: some View {
        VStack(spacing: Spacing.medium) {
            SliderRow(
                title: "강도",
                value: $intensity,
                range: 0...1,
                displayValue: "\(Int(intensity * 100))%"
            )
            SliderRow(
                title: "범위",
                value: $sizeMultiplier,
                range: 0.5...2.0,
                displayValue: "\(Int(sizeMultiplier * 100))%"
            )
        }
        .padding(Spacing.medium)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .appShadow(.card)
    }
}

private struct SliderRow: View {
    let title: LocalizedStringKey
    @Binding var value: Double
    let range: ClosedRange<Double>
    let displayValue: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            HStack {
                Text(title)
                    .font(.appFootnote)
                    .foregroundStyle(Color.appLabelSecondary)
                Spacer()
                Text(displayValue)
                    .font(.appCaption2)
                    .foregroundStyle(Color.appLabelTertiary)
                    .monospacedDigit()
                    .animation(nil, value: displayValue)
            }
            Slider(value: $value, in: range, step: 0.05)
                .tint(Color.appPrimary)
                .onChange(of: value) { _, _ in AppHaptics.selection() }
        }
    }
}

// MARK: - Detecting Skeleton View

private struct DetectingSkeletonView: View {
    var body: some View {
        VStack(spacing: Spacing.small) {
            ProgressView()
                .tint(Color.appPrimary)
                .scaleEffect(1.2)
            Text("인물 찾는 중...")
                .font(.appSubheadline)
                .foregroundStyle(Color.appLabelSecondary)
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.large)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .appShadow(.card)
    }
}

// MARK: - No Face Found View

private struct NoFaceFoundView: View {
    var body: some View {
        VStack(spacing: Spacing.small) {
            Image(systemName: "person.fill.questionmark")
                .resizable()
                .scaledToFit()
                .frame(width: 40)
                .foregroundStyle(Color.appLabelTertiary)
            Text("감지된 얼굴이 없습니다")
                .font(.appSubheadline)
                .foregroundStyle(Color.appLabelSecondary)
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.large)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }
}

// MARK: - Preview

#Preview("AI Editor – with sample faces") {
    NavigationStack {
        EditorView(image: previewImage())
    }
}

#Preview("AI Editor – Dark Mode") {
    NavigationStack {
        EditorView(image: previewImage())
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
