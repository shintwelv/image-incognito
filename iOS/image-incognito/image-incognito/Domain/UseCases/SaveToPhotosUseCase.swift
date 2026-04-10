//
//  SaveToPhotosUseCase.swift
//  image-incognito
//
//  Domain Use Case – Saves a masked UIImage to the Photo Library via the
//  injected repository. Propagates PhotoLibraryError on authorization denial
//  or write failure.
//

import UIKit

struct SaveToPhotosUseCase: Sendable {
    private let repository: any PhotoLibraryRepositoryProtocol

    nonisolated init(repository: any PhotoLibraryRepositoryProtocol) {
        self.repository = repository
    }

    nonisolated func execute(image: UIImage) async throws {
        try await repository.saveImageToAlbum(image)
    }
}
