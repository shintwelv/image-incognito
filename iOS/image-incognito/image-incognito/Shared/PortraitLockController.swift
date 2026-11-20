//
//  PortraitLockController.swift
//  image-incognito
//
//  Shared – root-level helpers that keep the app's window scene in portrait.
//
//  Info.plist and AppDelegate already restrict supported orientations, but on
//  iPadOS 26+ the system ignores `UIRequiresFullScreen` and can rotate the
//  display while leaving the scene in portrait, which draws the UI sideways.
//
//  `PortraitLockingHostingController` uses the supported iOS 26 replacement for
//  `UIRequiresFullScreen`: `prefersInterfaceOrientationLocked`. The invisible
//  `PortraitLockController` representable is a fallback for earlier systems,
//  where `UIWindowScene.requestGeometryUpdate` re-asserts portrait geometry.
//

import SwiftUI
import UIKit
import os

private let orientationLogger = Logger(subsystem: "com.image-incognito", category: "Orientation")

/// Root `UIHostingController` that asks the scene to lock its interface
/// orientation to portrait once the scene is portrait. The preference only
/// applies while this controller is the visible root of a full-screen scene.
final class PortraitLockingHostingController<Content: View>: UIHostingController<Content> {

    private var isLockEnabled = false
    private var lockTask: Task<Void, Never>?

    /// SwiftUI's hosting controller forwards the lock preference to an internal
    /// child. Returning `nil` makes the system use this controller's preference.
    @available(iOS 26.0, *)
    override var childForInterfaceOrientationLock: UIViewController? {
        nil
    }

    /// iOS 26+ replaces `UIRequiresFullScreen` with a per-view-controller
    /// orientation lock preference.
    @available(iOS 26.0, *)
    override var prefersInterfaceOrientationLocked: Bool {
        isLockEnabled
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 26.0, *) {
            lockWhenPortrait()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 26.0, *) {
            lockWhenPortrait()
        }
    }

    /// Locks only once the scene is portrait. If the app launches while the
    /// scene is landscape, request portrait first; locking a landscape scene
    /// would freeze the wrong orientation in place.
    @available(iOS 26.0, *)
    private func lockWhenPortrait() {
        guard let windowScene = view.window?.windowScene else { return }
        guard PortraitLockController.needsPortraitUpdate(current: windowScene.interfaceOrientation) else {
            enableOrientationLock()
            return
        }

        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { error in
            // Log only: the poll below retries or settles into portrait.
            orientationLogger.error("Portrait geometry update failed: \(String(describing: error), privacy: .public)")
        }

        lockTask?.cancel()
        lockTask = Task { @MainActor [weak self] in
            for _ in 0..<15 {
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled, let self else { return }
                guard let scene = self.view.window?.windowScene else { return }
                if !PortraitLockController.needsPortraitUpdate(current: scene.interfaceOrientation) {
                    self.enableOrientationLock()
                    return
                }
            }
        }
    }

    @available(iOS 26.0, *)
    private func enableOrientationLock() {
        guard !isLockEnabled else { return }
        isLockEnabled = true
        setNeedsUpdateOfPrefersInterfaceOrientationLocked()
    }
}

/// Invisible representable that re-asserts portrait geometry for its window scene
/// on systems that don't support the interface orientation lock preference.
struct PortraitLockController: UIViewControllerRepresentable {

    /// Pure decision helper, kept free of UIKit state so it can be unit tested.
    nonisolated static func needsPortraitUpdate(current: UIInterfaceOrientation) -> Bool {
        current != .portrait
    }

    func makeUIViewController(context: Context) -> PortraitLockViewController {
        PortraitLockViewController()
    }

    func updateUIViewController(_ uiViewController: PortraitLockViewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: PortraitLockViewController, coordinator: ()) {
        uiViewController.stopObservingOrientation()
    }
}

/// Zero-content controller whose only job is observing scene orientation changes.
final class PortraitLockViewController: UIViewController {

    private var isObserving = false
    private var checkTask: Task<Void, Never>?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startObservingOrientation()
        enforcePortraitIfNeeded()
        scheduleOrientationChecks()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // The representable is attached at the app root, so this only happens
        // when the hierarchy is torn down. Stop observing to avoid dangling work.
        if isBeingDismissed || isMovingFromParent {
            stopObservingOrientation()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Observation

    func startObservingOrientation() {
        guard !isObserving else { return }
        isObserving = true
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeviceOrientationChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeviceOrientationChange),
            name: UIScene.didActivateNotification,
            object: nil
        )
    }

    func stopObservingOrientation() {
        guard isObserving else { return }
        isObserving = false
        checkTask?.cancel()
        checkTask = nil
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.removeObserver(
            self,
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.removeObserver(
            self,
            name: UIScene.didActivateNotification,
            object: nil
        )
    }

    @objc private func handleDeviceOrientationChange(_ notification: Notification) {
        enforcePortraitIfNeeded()
        scheduleOrientationChecks()
    }

    // MARK: - Enforcement

    /// Requests portrait geometry for the attached window scene. No-op when the
    /// controller is not in a window or the scene is already portrait.
    func enforcePortraitIfNeeded() {
        guard let windowScene = view.window?.windowScene else { return }
        guard PortraitLockController.needsPortraitUpdate(current: windowScene.interfaceOrientation) else { return }

        requestPortraitUpdate(in: windowScene)
    }

    private func requestPortraitUpdate(in windowScene: UIWindowScene) {
        // Ask UIKit to re-evaluate the supported orientation mask as well, so a
        // scene that ignored Info.plist during rotation snaps back to portrait.
        windowScene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()

        windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { error in
            // Log only: a refused update is retried by `scheduleOrientationChecks`.
            orientationLogger.error("Portrait geometry update failed: \(String(describing: error), privacy: .public)")
        }
    }

    /// The scene's interface orientation can change *after* the device
    /// orientation notification fires, so keep checking briefly.
    private func scheduleOrientationChecks() {
        checkTask?.cancel()
        checkTask = Task { @MainActor [weak self] in
            for _ in 0..<10 {
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled, let self else { return }
                guard let windowScene = self.view.window?.windowScene else { return }
                guard PortraitLockController.needsPortraitUpdate(current: windowScene.interfaceOrientation) else {
                    return
                }
                self.requestPortraitUpdate(in: windowScene)
            }
        }
    }
}
