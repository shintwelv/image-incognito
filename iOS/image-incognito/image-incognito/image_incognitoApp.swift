//
//  image_incognitoApp.swift
//  image-incognito
//
//  Created by elvin on 3/27/26.
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    if ProcessInfo.processInfo.arguments.contains("--uitesting") {
        UIView.setAnimationsEnabled(false)
    }

    return true
  }

  func application(_ application: UIApplication,
                   supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    .portrait
  }
}

@main
struct image_incognitoApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @State private var settingsStore = SettingsStore()
    @State private var incomingImageStore = IncomingImageStore()

    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting")
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(settingsStore)
                .environment(incomingImageStore)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .onAppear {
                    if isUITesting {
                        injectUITestingState()
                    }
                }
        }
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
