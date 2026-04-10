//
//  RenderMaskUseCase.swift
//  image-incognito
//
//  Domain Use Case – Composites active face masks onto an image via the
//  injected repository. Runs on a background executor inside the repository.
//

import UIKit

struct RenderMaskUseCase: Sendable {
    private let repository: any MaskRenderingRepositoryProtocol

    nonisolated init(repository: any MaskRenderingRepositoryProtocol) {
        self.repository = repository
    }

    nonisolated func execute(
        image: UIImage,
        faces: [FaceBox],
        intensity: Double,
        sizeMultiplier: Double,
        solidCleanColor: UIColor
    ) async throws -> UIImage {
        try await repository.render(
            image: image,
            faces: faces,
            intensity: intensity,
            sizeMultiplier: sizeMultiplier,
            solidCleanColor: solidCleanColor
        )
    }
}
