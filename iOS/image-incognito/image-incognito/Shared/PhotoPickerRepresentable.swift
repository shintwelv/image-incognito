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
    @Binding var selectedImages: [UIImage]
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
                self?.parent.selectedImages = sorted
            }
        }
    }
}
