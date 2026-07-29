//
//  SwiftUIViewSnapshotTests.swift
//  image-incognitoTests
//
//  Snapshot tests for SwiftUI Views using SnapshotTestingHelper.
//  Executes instantly without spinning up heavy XCTest UI runner processes.
//

import Testing
import SwiftUI
import UIKit
@testable import image_incognito

@Suite("SwiftUIViewSnapshotTests")
@MainActor
struct SwiftUIViewSnapshotTests {

    private let store: SettingsStore = {
        let s = SettingsStore()
        s.resetEmojiPresets()
        return s
    }()

    private func makeSampleImage() -> UIImage {
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.systemGray5.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.systemIndigo.setFill()
            UIBezierPath(ovalIn: CGRect(x: 100, y: 100, width: 100, height: 100)).fill()
        }
    }

    // MARK: - FaceOverlayView Snapshots

    @Test("FaceOverlayView snapshot tests for all masking styles")
    func snapshotFaceOverlayViewAllStyles() {
        let styles: [MaskingStyle] = [.blurredGlass, .pixelArt, .crystalize, .solidClean, .emojiOverlay]

        for style in styles {
            let faceBox = FaceBox(
                rect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8),
                isMasked: true,
                style: style,
                selectedEmoji: "🐱"
            )
            let view = FaceOverlayView(
                faceBox: faceBox,
                solidCleanColor: .appPrimary,
                isSelected: true
            )
            .frame(width: 200, height: 200)

            SnapshotTestingHelper.assertSnapshot(
                matching: view,
                size: CGSize(width: 200, height: 200),
                named: "FaceOverlayView_\(style.rawValue)"
            )
        }
    }

    // MARK: - AdjustmentSlidersView Snapshots

    @Test("AdjustmentSlidersView snapshot tests for emojiOverlay and solidClean styles")
    func snapshotAdjustmentSlidersView() {
        var intensity = 0.75
        var sizeMultiplier = 1.0
        var color = Color.appPrimary
        var emoji = "😎"

        let emojiView = AdjustmentSlidersView(
            intensity: Binding(get: { intensity }, set: { intensity = $0 }),
            sizeMultiplier: Binding(get: { sizeMultiplier }, set: { sizeMultiplier = $0 }),
            selectedStyle: .emojiOverlay,
            solidCleanColor: Binding(get: { color }, set: { color = $0 }),
            selectedEmoji: Binding(get: { emoji }, set: { emoji = $0 })
        )
        .environment(store)

        SnapshotTestingHelper.assertSnapshot(
            matching: emojiView,
            size: CGSize(width: 375, height: 220),
            named: "AdjustmentSlidersView_emojiOverlay"
        )

        let solidView = AdjustmentSlidersView(
            intensity: Binding(get: { intensity }, set: { intensity = $0 }),
            sizeMultiplier: Binding(get: { sizeMultiplier }, set: { sizeMultiplier = $0 }),
            selectedStyle: .solidClean,
            solidCleanColor: Binding(get: { color }, set: { color = $0 }),
            selectedEmoji: Binding(get: { emoji }, set: { emoji = $0 })
        )
        .environment(store)

        SnapshotTestingHelper.assertSnapshot(
            matching: solidView,
            size: CGSize(width: 375, height: 200),
            named: "AdjustmentSlidersView_solidClean"
        )
    }

    // MARK: - ToastView Snapshot

    @Test("ToastView snapshot test")
    func snapshotToastView() {
        let toastView = ToastView(message: "saved.success", icon: "checkmark.circle.fill")
            .padding()

        SnapshotTestingHelper.assertSnapshot(
            matching: toastView,
            size: CGSize(width: 300, height: 80),
            named: "ToastView"
        )
    }

    // MARK: - Main Screens Snapshots

    @Test("EditorView snapshot test")
    func snapshotEditorView() {
        let sampleImage = makeSampleImage()
        let editorView = EditorView(images: [sampleImage])
            .environment(store)

        SnapshotTestingHelper.assertSnapshot(
            matching: editorView,
            size: CGSize(width: 375, height: 812),
            named: "EditorView"
        )
    }

    @Test("SettingsView snapshot test")
    func snapshotSettingsView() {
        let settingsView = SettingsView()
            .environment(store)

        SnapshotTestingHelper.assertSnapshot(
            matching: settingsView,
            size: CGSize(width: 375, height: 812),
            named: "SettingsView"
        )
    }

    @Test("ExportView snapshot test")
    func snapshotExportView() {
        let sampleImage = makeSampleImage()
        let exportView = ExportView(
            originalImages: [sampleImage],
            maskedImages: [sampleImage]
        )
        .environment(store)

        SnapshotTestingHelper.assertSnapshot(
            matching: exportView,
            size: CGSize(width: 375, height: 812),
            named: "ExportView"
        )
    }
}
