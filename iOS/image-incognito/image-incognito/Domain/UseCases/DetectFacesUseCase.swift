//
//  DetectFacesUseCase.swift
//  image-incognito
//
//  Domain Use Case – Detects faces in a UIImage via the injected repository.
//  Callers receive normalized FaceBox values (top-left origin, 0–1 scale).
//

import UIKit

struct DetectFacesUseCase {
    private let repository: FaceDetectionRepositoryProtocol

    init(repository: FaceDetectionRepositoryProtocol) {
        self.repository = repository
    }

    func execute(image: UIImage) async throws -> [FaceBox] {
        try await repository.detectFaces(in: image)
    }
}
