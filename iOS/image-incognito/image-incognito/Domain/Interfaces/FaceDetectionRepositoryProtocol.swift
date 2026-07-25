//
//  FaceDetectionRepositoryProtocol.swift
//  image-incognito
//
//  Domain Interface – Contract for face detection.
//  The Data layer (FaceDetectionService) conforms to this protocol;
//  the Presentation layer depends on this abstraction only.
//

import UIKit

protocol FaceDetectionRepositoryProtocol: Sendable {
    /// Detects faces and text/license plates in `image` and returns normalized FaceBox values
    /// (top-left origin, values 0–1 relative to the source image).
    func detectFaces(in image: UIImage, includeText: Bool) async throws -> [FaceBox]
}

extension FaceDetectionRepositoryProtocol {
    func detectFaces(in image: UIImage) async throws -> [FaceBox] {
        try await detectFaces(in: image, includeText: true)
    }
}
