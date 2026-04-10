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
        // 1. Check/Request Authorization
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
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

    init(albumName: String) {
        self.albumName = albumName
    }

    func getOrCreate() async throws -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)

        let existing = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        if let album = existing.firstObject {
            return album
        }

        // Not found — create it.
        try await PHPhotoLibrary.shared().performChanges { [albumName] in
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
        }

        // Re-fetch; return whichever album won (handles external races too).
        let created = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        return created.firstObject
    }
}
