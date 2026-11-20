//
//  DrawRegionOverlay.swift
//  image-incognito
//
//  Full-canvas drawing mode: scrim, instructions, shape picker, cancel, and a
//  live preview of the region being dragged.
//

import SwiftUI

// MARK: - Shape picker

struct ShapePickerRow: View {
    let selectedShape: MaskRegion.Shape
    let onSelect: (MaskRegion.Shape) -> Void

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            ForEach(MaskRegion.Shape.allCases) { shape in
                StylePill(
                    icon: shape.iconName,
                    label: shape.labelKey,
                    isSelected: selectedShape == shape
                ) {
                    onSelect(shape)
                }
                .accessibilityIdentifier("editor.shapePicker.\(shape.rawValue)")
                .accessibilityAddTraits(selectedShape == shape ? .isSelected : AccessibilityTraits())
                .frame(minWidth: 44, minHeight: 44)
            }
        }
    }
}

extension MaskRegion.Shape {
    var iconName: String {
        switch self {
        case .rectangle: return "rectangle"
        case .circle: return "circle"
        case .ellipse: return "oval"
        }
    }

    var labelKey: String {
        "editor.shape.\(rawValue)"
    }
}

// MARK: - Draw region overlay

struct DrawRegionOverlay: View {
    let imageRect: CGRect
    let selectedShape: MaskRegion.Shape
    let onShapeChange: (MaskRegion.Shape) -> Void
    let onCancel: () -> Void
    let onCommit: (CGRect) -> Void

    @State private var draftRect: CGRect?
    @State private var dragStart: CGPoint?

    var body: some View {
        ZStack {
            Color.black.opacity(0.32)
                .contentShape(Rectangle())
                .gesture(drawGesture)

            if let draftRect {
                previewShape(for: draftRect)
            }

            VStack(spacing: Spacing.small) {
                Text("editor.draw.instruction")
                    .font(.appBodyEmphasized)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                ShapePickerRow(selectedShape: selectedShape, onSelect: onShapeChange)

                Button {
                    AppHaptics.light()
                    onCancel()
                } label: {
                    Text("editor.draw.cancel")
                        .font(.appSubheadline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.medium)
                        .padding(.vertical, Spacing.xSmall)
                        .frame(minHeight: 44)
                        .background(Color.white.opacity(0.16))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("editor.drawCancel")
            }
            .padding(Spacing.medium)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
            .appShadow(.card)
            .padding(.horizontal, Spacing.medium)
            .padding(.top, Spacing.small)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("editor.drawOverlay")
    }

    // MARK: - Live preview

    private func previewShape(for rect: CGRect) -> some View {
        let frame = RegionHitTester.overlayFrame(
            for: MaskRegion(source: .manual, shape: selectedShape, rect: rect),
            imageRect: imageRect
        )

        return previewPath
            .fill(Color.appPrimary.opacity(0.28))
            .overlay {
                previewPath
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            }
            .frame(width: frame.width, height: frame.height)
            .position(x: frame.midX, y: frame.midY)
            .allowsHitTesting(false)
    }

    private var previewPath: AnyShape {
        switch selectedShape {
        case .rectangle:
            AnyShape(Rectangle())
        case .ellipse, .circle:
            AnyShape(Ellipse())
        }
    }

    // MARK: - Gesture

    private var drawGesture: some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .local)
            .onChanged { value in
                if dragStart == nil {
                    // Ignore drags that start outside the photo.
                    guard imageRect.contains(value.startLocation) else { return }
                    dragStart = value.startLocation
                }
                guard let start = dragStart else { return }
                draftRect = normalizedRect(from: start, to: value.location)
            }
            .onEnded { _ in
                defer {
                    draftRect = nil
                    dragStart = nil
                }
                guard let rect = draftRect, rect.width > 0, rect.height > 0 else { return }
                onCommit(rect)
            }
    }

    private func normalizedRect(from start: CGPoint, to end: CGPoint) -> CGRect {
        let startNorm = RegionGeometry.normalizedPoint(start, in: imageRect)
        let endNorm = RegionGeometry.normalizedPoint(end, in: imageRect)
        switch selectedShape {
        case .rectangle, .ellipse:
            return RegionGeometry.normalizedRect(from: startNorm, to: endNorm)
        case .circle:
            return RegionGeometry.circleRect(from: startNorm, to: endNorm)
        }
    }
}
