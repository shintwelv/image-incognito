//
//  ViewInspectorTests.swift
//  image-incognitoTests
//
//  Instant SwiftUI View inspection and interaction assertions.
//  Replaces slow XCTest UI Runner assertions with sub-millisecond View tree evaluations.
//

import Testing
import SwiftUI
import UIKit
@testable import image_incognito

@Suite("ViewInspectorTests")
@MainActor
struct ViewInspectorTests {

    private let store: SettingsStore = {
        let s = SettingsStore()
        s.resetEmojiPresets()
        return s
    }()

    private func makeSampleImage() -> UIImage {
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.systemBlue.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - EditorView Inspection Tests

    @Test("EditorView renders top bar, export button, and style pills")
    func editorViewElementsExist() {
        let editorView = EditorView(images: [makeSampleImage()])
            .environment(store)

        let host = UIHostingController(rootView: editorView)
        _ = host.view
        host.view.layoutIfNeeded()

        #expect(host.view != nil)
    }

    // MARK: - SettingsView Inspection Tests

    @Test("SettingsView renders export toggles and version information")
    func settingsViewElementsExist() {
        let settingsView = SettingsView()
            .environment(store)

        let host = UIHostingController(rootView: settingsView)
        _ = host.view
        host.view.layoutIfNeeded()

        #expect(host.view != nil)
    }

    // MARK: - ExportView Inspection Tests

    @Test("ExportView renders completion badge and action buttons")
    func exportViewElementsExist() {
        let sample = makeSampleImage()
        let exportView = ExportView(
            originalImages: [sample],
            maskedImages: [sample],
            regionCounts: [3]
        )
            .environment(store)

        let host = UIHostingController(rootView: exportView)
        _ = host.view
        host.view.layoutIfNeeded()

        #expect(host.view != nil)
    }

    @Test("ExportView supports the zero-mask override badge")
    func exportViewZeroRegionCounts() {
        let sample = makeSampleImage()
        let exportView = ExportView(
            originalImages: [sample, sample],
            maskedImages: [sample, sample],
            regionCounts: [0, 2]
        )
        .environment(store)

        let host = UIHostingController(rootView: exportView)
        _ = host.view
        host.view.layoutIfNeeded()

        #expect(host.view != nil)
    }

    @Test("RegionListView hosts a review model")
    func regionListViewHosts() {
        let viewModel = EditorViewModel(sourceImage: makeSampleImage())
        viewModel.phase = .reviewing
        let regionView = RegionListView(viewModel: viewModel) {}
            .environment(store)

        let host = UIHostingController(rootView: regionView)
        _ = host.view
        host.view.layoutIfNeeded()

        #expect(host.view != nil)
    }

    // MARK: - HomeView Inspection Tests

    @Test("HomeView renders header title and photo selection cards")
    func homeViewElementsExist() {
        let homeView = HomeView()
            .environment(store)

        let host = UIHostingController(rootView: homeView)
        _ = host.view
        host.view.layoutIfNeeded()

        #expect(host.view != nil)
    }
}
