//
//  RegionOverlayView.swift
//  image-incognito
//
//  Composable overlay for a `MaskRegion`: mask preview, suggestion/selection
//  rings, inclusion badge, and (for selected manual regions) resize handles.
//

import SwiftUI

// MARK: - Region Overlay View

struct RegionOverlayView: View {
    let region: MaskRegion
    let solidCleanColor: Color
    let isSelected: Bool
    /// Rendered image size in display points. Drag translations are normalized
    /// against this, not against the region's own overlay size.
    let canvasSize: CGSize

    var onToggleInclusion: (() -> Void)?
    var onMove: ((CGRect) -> Void)?
    var onResize: ((CGRect) -> Void)?
    var onGestureActiveChange: ((Bool) -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragStartRect: CGRect?

    // MARK: - Body

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                // Shape-specific hit target: taps/drags start only inside the
                // visible rectangle/ellipse. Handles and the badge live outside
                // an oval but remain independent child hit targets.
                maskShape
                    .fill(Color.white.opacity(0.001))
                    .contentShape(maskShape)
                    .onTapGesture {
                        onToggleInclusion?()
                    }
                    .gesture(moveGesture())

                if region.isIncluded {
                    maskLayer
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }

                borderLayer

                if region.isManual && isSelected {
                    resizeHandles(in: size)
                }
            }
            .overlay(alignment: .topTrailing) {
                inclusionBadge
                    .offset(x: Spacing.xSmall, y: -Spacing.xSmall)
            }
        }
        .animation(reduceMotion ? nil : AppAnimation.snappy, value: region.isIncluded)
        .animation(reduceMotion ? nil : AppAnimation.standard, value: region.shape)
        .animation(reduceMotion ? nil : AppAnimation.standard, value: region.style)
    }

    // MARK: - Mask

    @ViewBuilder
    private var maskLayer: some View {
        switch region.style {
        case .blurredGlass:
            maskShape
                .fill(.thickMaterial)
                .overlay {
                    maskShape
                        .fill(Color.white.opacity(0.15 * region.intensity))
                }
                .opacity(region.intensity)

        case .pixelArt:
            PixelArtMaskView(intensity: region.intensity, clipShape: maskShape)

        case .crystalize:
            CrystalizeMaskView(intensity: region.intensity, clipShape: maskShape)

        case .solidClean:
            maskShape
                .fill(solidCleanColor.opacity(region.intensity))

        case .emojiOverlay:
            EmojiMaskView(emoji: region.selectedEmoji, intensity: region.intensity)
        }
    }

    private var maskShape: AnyShape {
        switch region.shape {
        case .rectangle:
            AnyShape(Rectangle())
        case .ellipse, .circle:
            AnyShape(Ellipse())
        }
    }

    // MARK: - Border

    private var ringColor: Color {
        if isSelected { return Color.appPrimary }
        return region.isIncluded ? Color.white.opacity(0.9) : Color.white.opacity(0.55)
    }

    private var ringWidth: CGFloat {
        if isSelected { return 3 }
        return region.isIncluded ? 2 : 1.5
    }

    private var borderLayer: some View {
        maskShape
            .stroke(
                ringColor,
                style: StrokeStyle(
                    lineWidth: ringWidth,
                    dash: (region.isFace && !isSelected) ? [6, 4] : []
                )
            )
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            .allowsHitTesting(false)
    }

    // MARK: - Inclusion badge

    private var inclusionBadge: some View {
        Button {
            AppHaptics.light()
            onToggleInclusion?()
        } label: {
            Image(systemName: region.isIncluded ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(region.isIncluded ? Color.appPrimary : Color.white)
                .padding(Spacing.xSmall)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            LocalizedStringKey(region.isIncluded ? "editor.region.included" : "editor.region.excluded")
        )
        .accessibilityValue(
            LocalizedStringKey(region.isIncluded ? "editor.region.include" : "editor.region.exclude")
        )
        .accessibilityAddTraits(region.isIncluded ? .isSelected : AccessibilityTraits())
    }

    // MARK: - Resize handles

    private func resizeHandles(in size: CGSize) -> some View {
        ForEach(ResizeCorner.allCases, id: \.self) { corner in
            let point = corner.point(in: size)
            Circle()
                .fill(Color.white)
                .overlay(
                    Circle().stroke(Color.appPrimary, lineWidth: 2)
                )
                .frame(width: 12, height: 12)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Consume taps so handle taps never toggle inclusion.
                }
                .highPriorityGesture(resizeGesture(corner: corner))
                .position(x: point.x, y: point.y)
                .accessibilityLabel("editor.region.resizeHandle")
        }
    }

    // MARK: - Gestures

    private func moveGesture() -> some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                guard region.isManual, isSelected, let onMove else { return }
                if dragStartRect == nil {
                    dragStartRect = region.rect
                    onGestureActiveChange?(true)
                }
                guard let start = dragStartRect else { return }
                onMove(RegionGeometry.translated(start, by: value.translation, in: canvasSize))
            }
            .onEnded { _ in
                dragStartRect = nil
                onGestureActiveChange?(false)
            }
    }

    private func resizeGesture(corner: ResizeCorner) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                guard region.isManual, isSelected, let onResize else { return }
                if dragStartRect == nil {
                    dragStartRect = region.rect
                    onGestureActiveChange?(true)
                }
                guard let start = dragStartRect else { return }

                let dx = value.translation.width / max(canvasSize.width, 1)
                let dy = value.translation.height / max(canvasSize.height, 1)
                let anchor = corner.opposite.point(in: start)
                let moving = CGPoint(
                    x: min(max(corner.point(in: start).x + dx, 0), 1),
                    y: min(max(corner.point(in: start).y + dy, 0), 1)
                )
                onResize(RegionGeometry.resized(anchor: anchor, target: moving, shape: region.shape))
            }
            .onEnded { _ in
                dragStartRect = nil
                onGestureActiveChange?(false)
            }
    }

}

// MARK: - Resize corner

private enum ResizeCorner: CaseIterable, Hashable {
    case topLeading, topTrailing, bottomLeading, bottomTrailing

    func point(in rect: CGRect) -> CGPoint {
        switch self {
        case .topLeading: return CGPoint(x: rect.minX, y: rect.minY)
        case .topTrailing: return CGPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeading: return CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomTrailing: return CGPoint(x: rect.maxX, y: rect.maxY)
        }
    }

    func point(in size: CGSize) -> CGPoint {
        switch self {
        case .topLeading: return CGPoint(x: 0, y: 0)
        case .topTrailing: return CGPoint(x: size.width, y: 0)
        case .bottomLeading: return CGPoint(x: 0, y: size.height)
        case .bottomTrailing: return CGPoint(x: size.width, y: size.height)
        }
    }

    var opposite: ResizeCorner {
        switch self {
        case .topLeading: return .bottomTrailing
        case .topTrailing: return .bottomLeading
        case .bottomLeading: return .topTrailing
        case .bottomTrailing: return .topLeading
        }
    }
}

// MARK: - Pixel Art Mask View

struct PixelArtMaskView: View {
    let intensity: Double
    var clipShape: AnyShape = AnyShape(Ellipse())

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
        .clipShape(clipShape)
    }
}

// MARK: - Crystalize Mask View

struct CrystalizeMaskView: View {
    let intensity: Double
    var clipShape: AnyShape = AnyShape(Ellipse())

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let step = max(size.width, size.height) / 6
            Canvas { context, size in
                for x in stride(from: 0, to: size.width, by: step) {
                    for y in stride(from: 0, to: size.height, by: step) {
                        var path = Path()
                        path.move(to: CGPoint(x: x + step/2, y: y))
                        path.addLine(to: CGPoint(x: x + step, y: y + step/2))
                        path.addLine(to: CGPoint(x: x + step/2, y: y + step))
                        path.addLine(to: CGPoint(x: x, y: y + step/2))
                        path.closeSubpath()

                        let baseAlpha = 0.6 + (Double((Int(x+y) % 3)) * 0.2)
                        context.fill(path, with: .color(Color(white: 0.8).opacity(baseAlpha * intensity)))
                    }
                }
            }
        }
        .clipShape(clipShape)
    }
}

// MARK: - Emoji Mask View

struct EmojiMaskView: View {
    let emoji: String
    let intensity: Double

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            Text(emoji.isEmpty ? "😎" : emoji)
                .font(.system(size: max(8, side * 0.85)))
                .minimumScaleFactor(0.1)
                .lineLimit(1)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .opacity(intensity)
        }
    }
}
