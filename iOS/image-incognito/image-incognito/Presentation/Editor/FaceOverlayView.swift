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
            }
            borderLayer
        }
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
