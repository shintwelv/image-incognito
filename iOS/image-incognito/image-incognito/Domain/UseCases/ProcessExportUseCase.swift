//
//  ProcessExportUseCase.swift
//  image-incognito
//
//  Domain Use Case – Applies ExportSettings (resolution, metadata stripping)
//  to a masked UIImage before saving or sharing. Never throws; falls back
//  to the original image on any processing error.
//

import UIKit

struct ProcessExportUseCase: Sendable {
    private let repository: any ExportProcessingRepositoryProtocol

    nonisolated init(repository: any ExportProcessingRepositoryProtocol) {
        self.repository = repository
    }

    nonisolated func execute(image: UIImage, settings: ExportSettings) async -> UIImage {
        await repository.process(image, settings: settings)
    }
}
