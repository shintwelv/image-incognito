//
//  PhotoLibraryRepositoryProtocol.swift
//  image-incognito
//
//  Domain Interface – Contract for photo library write operations.
//  The Data layer (PhotoLibraryService) conforms to this protocol.
//

import UIKit

protocol PhotoLibraryRepositoryProtocol: Sendable {
    /// Saves `image` to the app's dedicated album in the Photo Library.
    /// Throws `PhotoLibraryError` if authorization is denied or the write fails.
    func saveImageToAlbum(_ image: UIImage) async throws
}
