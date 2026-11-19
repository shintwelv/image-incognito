//
//  InteractivePopGestureController.swift
//  image-incognito
//
//  Turns the navigation controller's interactive pop gesture off while the
//  editor has unsaved drafts. The custom back button already shows a discard
//  confirmation; disabling the system edge-swipe keeps that confirmation from
//  being bypassed.
//

import SwiftUI
import UIKit

struct InteractivePopGestureController: UIViewControllerRepresentable {

    /// `false` while the editor has drafts that would be lost on exit.
    let isEnabled: Bool

    func makeUIViewController(context: Context) -> Controller {
        Controller()
    }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.isEnabled = isEnabled
        controller.apply()
    }

    static func dismantleUIViewController(_ controller: Controller, coordinator: ()) {
        controller.restore()
    }

    // MARK: - Hosted controller

    final class Controller: UIViewController {

        var isEnabled = true
        private weak var interactivePopGestureRecognizer: UIGestureRecognizer?

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            apply()
        }

        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            restore()
        }

        func apply() {
            guard let recognizer = navigationController?.interactivePopGestureRecognizer else { return }
            interactivePopGestureRecognizer = recognizer
            recognizer.isEnabled = isEnabled
        }

        func restore() {
            interactivePopGestureRecognizer?.isEnabled = true
            interactivePopGestureRecognizer = nil
        }
    }
}
