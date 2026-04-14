//
//  PhotoLibraryService.swift
//  image-incognito
//
//  Data Service – Manages photo library operations (saving to albums,
//  authorization).
//

import Photos
import UIKit

/// Errors specific to the photo library operations.
enum PhotoLibraryError: Error, LocalizedError {
    case unauthorized
    case failedToSave
    case failedToGetOrCreateAlbum

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return String(localized: "사진 접근 권한이 없습니다. 설정 앱에서 권한을 허용해주세요.")
        case .failedToSave:
            return String(localized: "이미지를 저장하는 데 실패했습니다.")
        case .failedToGetOrCreateAlbum:
            return String(localized: "앨범을 생성하거나 찾는 데 실패했습니다.")
        }
    }
}

final class PhotoLibraryService: PhotoLibraryRepositoryProtocol {
    
    // MARK: - Constants

    private let albumName = "Incognify"

    // Serializes album lookup/creation to prevent concurrent duplicate creation.
    private let albumGateway: AlbumGateway

    init() {
        self.albumGateway = AlbumGateway(albumName: "Incognify")
    }

    // MARK: - Public API

    /// Saves the `image` to the "Incognify" album in the Photo Library.
    /// Requests authorization if not already granted.
    nonisolated func saveImageToAlbum(_ image: UIImage) async throws {
        // 1. Check/Request Authorization (.readWrite is required to fetch/find existing albums)
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else {
            throw PhotoLibraryError.unauthorized
        }

        // 2. Find or Create Album (serialized via actor to prevent duplicates)
        let album = try await albumGateway.getOrCreate()

        // 3. Perform Changes
        try await PHPhotoLibrary.shared().performChanges {
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            guard let assetPlaceholder = assetChangeRequest.placeholderForCreatedAsset else { return }
            
            if let album = album {
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                albumChangeRequest?.addAssets([assetPlaceholder] as NSArray)
            }
        }
    }
}

// MARK: - AlbumGateway

/// Serializes album lookup and creation so concurrent saves never produce duplicate albums.
private actor AlbumGateway {
    private let albumName: String
    private var cachedAlbumIdentifier: String?

    init(albumName: String) {
        self.albumName = albumName
    }

    func getOrCreate() async throws -> PHAssetCollection? {
        // 1. Check by cached identifier first (fastest and most reliable in-session)
        if let id = cachedAlbumIdentifier {
            let result = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil)
            if let album = result.firstObject {
                return album
            }
        }

        // 2. Search by name (handles cross-session or manual creation)
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        
        // Use .albumRegular for the most common user-created album type
        let existing = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: fetchOptions)
        if let album = existing.firstObject {
            self.cachedAlbumIdentifier = album.localIdentifier
            return album
        }

        // 3. Not found — create it.
        var newIdentifier: String?
        try await PHPhotoLibrary.shared().performChanges { [albumName] in
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            newIdentifier = request.placeholderForCreatedAssetCollection.localIdentifier
        }

        // 4. Fetch the newly created album by its identifier (more reliable than re-fetching by name immediately)
        if let id = newIdentifier {
            let result = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil)
            if let created = result.firstObject {
                self.cachedAlbumIdentifier = created.localIdentifier
                return created
            }
        }

        return nil
    }
}
