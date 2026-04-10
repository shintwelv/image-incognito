//
//  PhotoPickerRepresentable.swift
//  image-incognito
//
//  Shared – PHPicker wrapper (UIViewControllerRepresentable)
//  Calls PHPickerViewController and returns up to 5 selected UIImages.
//

import SwiftUI
import PhotosUI

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

            let group = DispatchGroup()
            var orderedImages: [Int: UIImage] = [:]

            for (index, result) in results.enumerated() {
                guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                    if let image = object as? UIImage {
                        orderedImages[index] = image
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) { [weak self] in
                let sorted = orderedImages.sorted { $0.key < $1.key }.map(\.value)
                self?.parent.onImagesSelected(sorted)
            }
        }
    }
}
