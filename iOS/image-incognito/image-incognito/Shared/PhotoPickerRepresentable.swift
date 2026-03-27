//
//  PhotoPickerRepresentable.swift
//  image-incognito
//
//  Shared – PHPicker wrapper (UIViewControllerRepresentable)
//  Calls PHPickerViewController and returns the selected UIImage.
//

import SwiftUI
import PhotosUI

struct PhotoPickerRepresentable: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var onDismiss: (() -> Void)?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
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

            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                guard let image = object as? UIImage else { return }
                DispatchQueue.main.async {
                    self?.parent.selectedImage = image
                }
            }
        }
    }
}
