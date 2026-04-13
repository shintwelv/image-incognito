//
//  PhotoPickerRepresentable.swift
//  image-incognito
//
//  Shared – PHPicker wrapper (UIViewControllerRepresentable)
//  Calls PHPickerViewController and returns up to 5 selected UIImages.
//

import SwiftUI
import PhotosUI

/// Thin `@unchecked Sendable` box for bridging ObjC reference types into
/// Swift 6 structured concurrency (`NSItemProvider` is not `Sendable`).
private struct SendableBox<T>: @unchecked Sendable {
    nonisolated(unsafe) let value: T
}

protocol PhotoPickerImageLoading: Sendable {
    nonisolated func canLoadImage() -> Bool
    nonisolated func loadImage() async -> UIImage?
}

private struct ItemProviderImageLoader: PhotoPickerImageLoading {
    private let itemProvider: SendableBox<NSItemProvider>

    init(itemProvider: NSItemProvider) {
        self.itemProvider = SendableBox(value: itemProvider)
    }

    nonisolated func canLoadImage() -> Bool {
        itemProvider.value.canLoadObject(ofClass: UIImage.self)
    }

    nonisolated func loadImage() async -> UIImage? {
        await withCheckedContinuation { continuation in
            itemProvider.value.loadObject(ofClass: UIImage.self) { object, _ in
                continuation.resume(returning: object as? UIImage)
            }
        }
    }
}

struct PhotoPickerRepresentable: UIViewControllerRepresentable {
    /// Called immediately after the picker is dismissed with a non-empty selection,
    /// before the images have finished decoding.
    var onLoadingStarted: () -> Void
    /// Called once all selected images have been decoded and are ready.
    var onImagesSelected: ([UIImage]) -> Void
    var onDismiss: (() -> Void)?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 5
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - Coordinator

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PhotoPickerRepresentable

        init(_ parent: PhotoPickerRepresentable) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true) { [weak self] in
                self?.parent.onDismiss?()
            }

            guard !results.isEmpty else { return }

            // Notify immediately so the caller can show a loading state
            // before the (potentially slow) image decoding begins.
            parent.onLoadingStarted()

            // Capture the callback by value so it is always called even if the
            // coordinator is deallocated before the Task fires.
            let onImagesSelected = parent.onImagesSelected

            Task {
                let loaders = results.map { ItemProviderImageLoader(itemProvider: $0.itemProvider) }
                onImagesSelected(await PhotoPickerRepresentable.loadImages(from: loaders))
            }
        }
    }

    nonisolated static func loadImages(from loaders: [any PhotoPickerImageLoading]) async -> [UIImage] {
        await withTaskGroup(of: (Int, UIImage?).self) { group in
            for (index, loader) in loaders.enumerated() {
                guard loader.canLoadImage() else { continue }
                group.addTask {
                    (index, await loader.loadImage())
                }
            }

            var ordered: [Int: UIImage] = [:]
            for await (index, image) in group {
                if let image {
                    ordered[index] = image
                }
            }
            return ordered.sorted { $0.key < $1.key }.map(\.value)
        }
    }
}
