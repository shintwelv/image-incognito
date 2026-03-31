//
//  CameraPickerRepresentable.swift
//  image-incognito
//
//  Shared – UIImagePickerController wrapper for camera capture.
//  Presents the system camera and returns the captured UIImage.
//

import SwiftUI

struct CameraPickerRepresentable: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var onDismiss: (() -> Void)?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: CameraPickerRepresentable

        init(_ parent: CameraPickerRepresentable) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = info[.originalImage] as? UIImage
            picker.dismiss(animated: true) { [weak self] in
                self?.parent.onDismiss?()
                if let image {
                    self?.parent.selectedImage = image
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) { [weak self] in
                self?.parent.onDismiss?()
            }
        }
    }
}
