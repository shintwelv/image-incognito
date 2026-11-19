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
import Vision
@testable import image_incognito

@MainActor
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

    @Test("automatic masking uses only the face detection Vision request")
    func automaticMaskingUsesOnlyFaceDetectionRequest() {
        let requests = FaceDetectionService.faceDetectionRequests()

        #expect(requests.count == 1)
        #expect(requests.first is VNDetectFaceRectanglesRequest)
        #expect(requests.allSatisfy { !($0 is VNRecognizeTextRequest) })
    }

    #if !targetEnvironment(simulator)
    @Test("device Vision leaves text-only images without automatic masks")
    func deviceVisionLeavesTextOnlyImageUnmasked() async throws {
        let size = CGSize(width: 600, height: 300)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 88, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            ("ABC 1234" as NSString).draw(
                in: CGRect(x: 60, y: 100, width: 480, height: 100),
                withAttributes: attributes
            )
        }

        let detectedFaces = try await service.detectFaces(in: image)

        #expect(detectedFaces.isEmpty)
    }
    #endif
}
