//
//  SaveToPhotosUseCase.swift
//  image-incognito
//
//  Domain Use Case – Saves a masked UIImage to the Photo Library via the
//  injected repository. Propagates PhotoLibraryError on authorization denial
//  or write failure.
//

import UIKit

struct SaveToPhotosUseCase {
    private let repository: PhotoLibraryRepositoryProtocol

    init(repository: PhotoLibraryRepositoryProtocol) {
        self.repository = repository
    }

    func execute(image: UIImage) async throws {
        try await repository.saveImageToAlbum(image)
    }
}
