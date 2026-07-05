//
//  FaceDetectionServiceTests.swift
//  image-incognitoTests
//
//  Unit tests for FaceDetectionService: verifies empty-image handling, Vision
//  coordinate conversion, and UIImage orientation bridging.
//

import ImageIO
import Testing
import UIKit
@testable import image_incognito

@Suite("FaceDetectionService")
struct FaceDetectionServiceTests {

    private let service = FaceDetectionService()

    @Test("detectFaces returns an empty array when the image has no cgImage")
    func detectFacesWithoutCGImage() async throws {
        let result = try await service.detectFaces(in: UIImage())

        #expect(result.isEmpty)
    }

    @Test("topLeftBoundingBox converts Vision bottom-left coordinates to UIKit top-left coordinates")
    func topLeftBoundingBoxConvertsCoordinates() {
        let convertedBottom = FaceDetectionService.topLeftBoundingBox(
            fromVisionBoundingBox: CGRect(x: 0.2, y: 0.05, width: 0.2, height: 0.2)
        )
        let convertedTop = FaceDetectionService.topLeftBoundingBox(
            fromVisionBoundingBox: CGRect(x: 0.2, y: 0.75, width: 0.2, height: 0.2)
        )
        let convertedCenter = FaceDetectionService.topLeftBoundingBox(
            fromVisionBoundingBox: CGRect(x: 0.2, y: 0.4, width: 0.2, height: 0.2)
        )

        #expect(abs(convertedBottom.minY - 0.75) < 0.001)
        #expect(abs(convertedTop.minY - 0.05) < 0.001)
        #expect(abs(convertedCenter.minY - 0.4) < 0.001)
        #expect(abs(convertedBottom.width - 0.2) < 0.001)
        #expect(abs(convertedBottom.height - 0.2) < 0.001)
    }

    @Test("topLeftBoundingBox preserves full-frame bounds")
    func topLeftBoundingBoxPreservesFullFrame() {
        let converted = FaceDetectionService.topLeftBoundingBox(
            fromVisionBoundingBox: CGRect(x: 0, y: 0, width: 1, height: 1)
        )

        #expect(converted == CGRect(x: 0, y: 0, width: 1, height: 1))
    }

    @Test("CGImagePropertyOrientation maps every UIImage orientation correctly")
    func cgImagePropertyOrientationMapping() {
        #expect(CGImagePropertyOrientation(.up) == .up)
        #expect(CGImagePropertyOrientation(.down) == .down)
        #expect(CGImagePropertyOrientation(.left) == .left)
        #expect(CGImagePropertyOrientation(.right) == .right)
        #expect(CGImagePropertyOrientation(.upMirrored) == .upMirrored)
        #expect(CGImagePropertyOrientation(.downMirrored) == .downMirrored)
        #expect(CGImagePropertyOrientation(.leftMirrored) == .leftMirrored)
        #expect(CGImagePropertyOrientation(.rightMirrored) == .rightMirrored)
    }
}
