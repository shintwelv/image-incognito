//
//  FaceOverlayView.swift
//  image-incognito
//
//  Composable overlay drawn on top of each detected FaceBox.
//  Contains the mask layer (blurredGlass / pixelArt / solidClean)
//  and the selection border ring.
//

import SwiftUI

// MARK: - Face Overlay View

struct FaceOverlayView: View {
    let faceBox: FaceBox
    let solidCleanColor: Color
    let isSelected: Bool

    var body: some View {
        ZStack {
            if faceBox.isMasked {
                maskLayer
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
            borderLayer
        }
        .animation(AppAnimation.standard, value: faceBox.isMasked)
        .animation(AppAnimation.standard, value: faceBox.style)
    }

    @ViewBuilder
    private var maskLayer: some View {
        switch faceBox.style {
        case .blurredGlass:
            Ellipse()
                .fill(.ultraThinMaterial)
                .overlay {
                    Ellipse()
                        .fill(Color.white.opacity(0.15 * faceBox.intensity))
                }
                .opacity(faceBox.intensity)

        case .pixelArt:
            PixelArtMaskView(intensity: faceBox.intensity)

        case .crystalize:
            CrystalizeMaskView(intensity: faceBox.intensity)

        case .solidClean:
            Ellipse()
                .fill(solidCleanColor.opacity(faceBox.intensity))
        }
    }

    private var borderLayer: some View {
        Ellipse()
            .stroke(
                isSelected ? Color.appPrimary : (faceBox.isMasked ? Color.white.opacity(0.85) : Color.white.opacity(0.45)),
                lineWidth: isSelected ? 3 : (faceBox.isMasked ? 2 : 1.5)
            )
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Pixel Art Mask View

struct PixelArtMaskView: View {
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
        .clipShape(Ellipse())
    }
}

// MARK: - Crystalize Mask View

struct CrystalizeMaskView: View {
    let intensity: Double
    
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
                        
                        let alpha = 0.3 + (Double((Int(x+y) % 3)) * 0.2)
                        context.fill(path, with: .color(Color(white: 0.8).opacity(alpha * intensity)))
                    }
                }
            }
        }
        .clipShape(Ellipse())
    }
}
