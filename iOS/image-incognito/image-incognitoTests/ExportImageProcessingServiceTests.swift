//
//  ExportImageProcessingServiceTests.swift
//  image-incognitoTests
//
//  Unit tests for ExportImageProcessingService: verifies downsampling, no-op
//  paths, and that metadata-rewrite settings preserve image geometry.
//

import Testing
import UIKit
@testable import image_incognito

@Suite("ExportImageProcessingService")
struct ExportImageProcessingServiceTests {

    private let service = ExportImageProcessingService()

    @Test("process returns the original image when all export settings are no-ops")
    func processNoOpReturnsOriginalImage() async {
        let image = makeTestImage(size: CGSize(width: 800, height: 600))
        let settings = ExportSettings(
            removeLocation: false,
            removeExif: false,
            keepOriginalResolution: true
        )

        let result = await service.process(image, settings: settings)

        #expect(result === image)
    }

    @Test("process keeps a small image untouched when downsampling is enabled")
    func processSmallImageRemainsUnchanged() async {
        let image = makeTestImage(size: CGSize(width: 640, height: 480))
        let settings = ExportSettings(
            removeLocation: false,
            removeExif: false,
            keepOriginalResolution: false
        )

        let result = await service.process(image, settings: settings)

        #expect(result === image)
    }

    @Test("process downsamples large landscape images to a longest edge of 1080")
    func processDownsamplesLandscapeImage() async {
        let source = makeTestImage(size: CGSize(width: 2400, height: 1200))
        guard let cgImage = source.cgImage else {
            Issue.record("Expected test image to expose cgImage")
            return
        }
        let image = UIImage(cgImage: cgImage, scale: 1, orientation: .up)
        let settings = ExportSettings(
            removeLocation: false,
            removeExif: false,
            keepOriginalResolution: false
        )

        let result = await service.process(image, settings: settings)

        #expect(result !== image)
        #expect(result.size == CGSize(width: 1080, height: 540))
    }

    @Test("process downsamples large portrait images while preserving aspect ratio")
    func processDownsamplesPortraitImage() async {
        let source = makeTestImage(size: CGSize(width: 1200, height: 2400))
        guard let cgImage = source.cgImage else {
            Issue.record("Expected test image to expose cgImage")
            return
        }
        let image = UIImage(cgImage: cgImage, scale: 1, orientation: .up)
        let settings = ExportSettings(
            removeLocation: false,
            removeExif: false,
            keepOriginalResolution: false
        )

        let result = await service.process(image, settings: settings)

        #expect(result.size == CGSize(width: 540, height: 1080))
    }

    @Test("process preserves scale and orientation while downsampling")
    func processPreservesScaleAndOrientation() async {
        let source = makeTestImage(size: CGSize(width: 2400, height: 1200))
        guard let cgImage = source.cgImage else {
            Issue.record("Expected test image to expose cgImage")
            return
        }

        let image = UIImage(cgImage: cgImage, scale: 3, orientation: .rightMirrored)
        let settings = ExportSettings(
            removeLocation: false,
            removeExif: false,
            keepOriginalResolution: false
        )

        let result = await service.process(image, settings: settings)

        #expect(result.scale == 3)
        #expect(result.imageOrientation == .rightMirrored)
    }

    @Test("process rewrites image data for metadata stripping without changing its geometry")
    func processMetadataRewritePreservesGeometry() async {
        let image = makeTestImage(size: CGSize(width: 640, height: 960))
        let settings = ExportSettings(
            removeLocation: true,
            removeExif: true,
            keepOriginalResolution: true
        )

        let result = await service.process(image, settings: settings)

        #expect(result.size == image.size)
        #expect(result.scale == image.scale)
    }
}
