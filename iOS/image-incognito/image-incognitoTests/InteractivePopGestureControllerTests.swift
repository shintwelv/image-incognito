//
//  InteractivePopGestureControllerTests.swift
//  image-incognitoTests
//
//  Lightweight checks for the editor's draft-exit guard on the system
//  edge-swipe gesture.
//

import Testing
import UIKit
@testable import image_incognito

@Suite("InteractivePopGestureController")
@MainActor
struct InteractivePopGestureControllerTests {

    @Test("Controller disables and restores the navigation pop gesture")
    func disablesAndRestoresPopGesture() throws {
        let navigationController = UINavigationController(rootViewController: UIViewController())
        navigationController.loadViewIfNeeded()

        let controller = InteractivePopGestureController.Controller()
        controller.loadViewIfNeeded()
        navigationController.pushViewController(controller, animated: false)
        controller.loadViewIfNeeded()

        let gesture = try #require(navigationController.interactivePopGestureRecognizer)

        controller.isEnabled = false
        controller.apply()
        #expect(gesture.isEnabled == false)

        controller.restore()
        #expect(gesture.isEnabled == true)
    }

    @Test("Applying before attachment is a no-op")
    func applyWithoutNavigationControllerDoesNotCrash() {
        let controller = InteractivePopGestureController.Controller()
        controller.loadViewIfNeeded()
        controller.isEnabled = false
        controller.apply()
        controller.restore()
        #expect(controller.navigationController == nil)
    }
}
