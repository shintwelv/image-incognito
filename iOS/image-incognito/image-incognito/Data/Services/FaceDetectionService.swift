//
//  FaceDetectionService.swift
//  image-incognito
//
//  Data Service – Detects faces in a UIImage using the Vision framework.
//  Conforms to FaceDetectionRepositoryProtocol so the Domain and Presentation
//  layers have no direct Vision dependency.
//
//  Coordinate conversion: Vision uses bottom-left origin; this service
//  normalizes all results to top-left origin (UIKit/SwiftUI convention).
//
//  Orientation: VNImageRequestHandler must receive the UIImage's display
//  orientation so Vision interprets pixel data correctly. Without it,
//  photos taken in portrait (imageOrientation=.right) are processed as
//  landscape and bounding boxes are misaligned in the display coordinate
//  space.
//

import UIKit
import Vision

final class FaceDetectionService: FaceDetectionRepositoryProtocol {

    // MARK: - FaceDetectionRepositoryProtocol

    func detectFaces(in image: UIImage) async throws -> [FaceBox] {
        guard let cgImage = image.cgImage else { return [] }

        let request = VNDetectFaceRectanglesRequest()
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try handler.perform([request])
                continuation.resume()
            } catch {
                continuation.resume(throwing: error)
            }
        }

        return (request.results ?? []).map { observation in
            // Vision uses bottom-left origin; convert to top-left (UIKit/SwiftUI).
            let flipped = CGRect(
                x: observation.boundingBox.origin.x,
                y: 1 - observation.boundingBox.origin.y - observation.boundingBox.height,
                width: observation.boundingBox.width,
                height: observation.boundingBox.height
            )
            return FaceBox(rect: flipped)
        }
    }
}

// MARK: - UIImage.Orientation → CGImagePropertyOrientation

/// Bridges `UIImage.Orientation` to the EXIF-based `CGImagePropertyOrientation`
/// required by `VNImageRequestHandler`. Without this mapping, Vision processes
/// every image as if it were unrotated (.up) and returns bounding boxes in the
/// wrong coordinate space for portrait photos.
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
        case .up:            self = .up
        case .down:          self = .down
        case .left:          self = .left
        case .right:         self = .right
        case .upMirrored:    self = .upMirrored
        case .downMirrored:  self = .downMirrored
        case .leftMirrored:  self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default:    self = .up
        }
    }
}
