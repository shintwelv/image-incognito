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

import UIKit
import Vision

final class FaceDetectionService: FaceDetectionRepositoryProtocol {

    // MARK: - FaceDetectionRepositoryProtocol

    func detectFaces(in image: UIImage) async throws -> [FaceBox] {
        guard let cgImage = image.cgImage else { return [] }

        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

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
