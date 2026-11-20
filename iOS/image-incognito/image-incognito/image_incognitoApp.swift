//
//  image_incognitoApp.swift
//  image-incognito
//
//  Created by elvin on 3/27/26.
//

import SwiftUI
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        if ProcessInfo.processInfo.arguments.contains("--uitesting") {
            UIView.setAnimationsEnabled(false)
        }

        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        .portrait
    }
}

/// Owns the app's single window and its app-wide observable stores.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private let settingsStore = SettingsStore()
    private let incomingImageStore = IncomingImageStore()

    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting")
    }

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let rootView = HomeView()
            .environment(settingsStore)
            .environment(incomingImageStore)
            .background(
                PortraitLockController()
                    .frame(width: 0, height: 0)
                    .accessibilityHidden(true)
            )
            .onAppear { [weak self] in
                guard let self, self.isUITesting else { return }
                self.injectUITestingState()
            }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = PortraitLockingHostingController(rootView: rootView)
        self.window = window
        window.makeKeyAndVisible()

        for context in connectionOptions.urlContexts {
            handleIncomingURL(context.url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts {
            handleIncomingURL(context.url)
        }
    }

    /// iOS 27 scene-level orientation mask. This replaces the deprecated
    /// app-delegate mask for this scene and keeps the window portrait.
    @available(iOS 27.0, *)
    func supportedInterfaceOrientations(for windowScene: UIWindowScene) -> UIInterfaceOrientationMask {
        .portrait
    }

    private func handleIncomingURL(_ url: URL) {
        Task {
            if url.isFileURL {
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                guard let data = try? Data(contentsOf: url),
                      let image = UIImage(data: data) else { return }
                incomingImageStore.pendingImages = [image]
            } else if url.scheme == "incognify" {
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                   let pathItem = components.queryItems?.first(where: { $0.name == "path" })?.value,
                   let targetURL = URL(string: pathItem),
                   targetURL.isFileURL {
                    let accessed = targetURL.startAccessingSecurityScopedResource()
                    defer { if accessed { targetURL.stopAccessingSecurityScopedResource() } }
                    guard let data = try? Data(contentsOf: targetURL),
                          let image = UIImage(data: data) else { return }
                    incomingImageStore.pendingImages = [image]
                }
            }
        }
    }

    /// Injects stub images so UI tests can navigate to EditorView on Simulator
    /// (where VisionKit face detection is unavailable).
    private func injectUITestingState() {
        let size = CGSize(width: 400, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        let stubImage = renderer.image { ctx in
            UIColor.systemGray5.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        incomingImageStore.pendingImages = [stubImage]
    }
}
