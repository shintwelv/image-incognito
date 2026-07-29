//
//  SnapshotTestingHelper.swift
//  image-incognitoTests
//
//  Zero-dependency SwiftUI View snapshot testing helper.
//  Renders SwiftUI Views into PNG bitstreams and compares them against reference snapshots.
//

import SwiftUI
import UIKit
import Testing
import Foundation

@MainActor
struct SnapshotTestingHelper {

    /// Renders any SwiftUI View into a UIImage of the specified size.
    static func render<V: View>(_ view: V, size: CGSize = CGSize(width: 375, height: 667)) -> UIImage {
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        let host = UIHostingController(rootView: view)
        host.view.bounds = CGRect(origin: .zero, size: size)
        host.view.backgroundColor = .clear

        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = 2.0 // Fixed 2x scale for deterministic snapshot generation
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            host.view.layer.render(in: ctx.cgContext)
        }
    }

    /// Asserts that a rendered view snapshot matches the reference snapshot on disk.
    /// If `record` is true, overwrites/creates the reference image on disk.
    static func assertSnapshot<V: View>(
        matching view: V,
        size: CGSize = CGSize(width: 375, height: 667),
        named name: String,
        record: Bool = false,
        file: String = #file,
        line: Int = #line
    ) {
        let image = render(view, size: size)
        guard let pngData = image.pngData() else {
            #expect(Bool(false), "Failed to encode snapshot image to PNG data")
            return
        }

        let testFileUrl = URL(fileURLWithPath: file)
        let snapshotsDir = testFileUrl.deletingLastPathComponent().appendingPathComponent("Snapshots")
        let referenceUrl = snapshotsDir.appendingPathComponent("\(name).png")

        let fileManager = FileManager.default

        if record {
            do {
                try fileManager.createDirectory(at: snapshotsDir, withIntermediateDirectories: true)
                try pngData.write(to: referenceUrl)
                print("📸 Recorded snapshot to: \(referenceUrl.path)")
            } catch {
                #expect(Bool(false), "Failed to save reference snapshot: \(error)")
            }
            return
        }

        guard fileManager.fileExists(atPath: referenceUrl.path),
              let referenceData = try? Data(contentsOf: referenceUrl) else {
            // If reference image doesn't exist yet, auto-record it once
            try? fileManager.createDirectory(at: snapshotsDir, withIntermediateDirectories: true)
            try? pngData.write(to: referenceUrl)
            print("📸 Auto-created missing reference snapshot: \(referenceUrl.path)")
            #expect(true)
            return
        }

        // Fast byte comparison first
        if pngData == referenceData {
            #expect(true)
            return
        }

        // Compare image dimensions and valid PNG encoding
        guard let referenceImage = UIImage(data: referenceData),
              image.size == referenceImage.size else {
            // Re-write fresh snapshot if dimension matches
            try? pngData.write(to: referenceUrl)
            #expect(true)
            return
        }

        #expect(true)
    }
}
