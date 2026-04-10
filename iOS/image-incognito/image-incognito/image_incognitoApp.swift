//
//  image_incognitoApp.swift
//  image-incognito
//
//  Created by elvin on 3/27/26.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct image_incognitoApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @State private var settingsStore = SettingsStore()
    @State private var incomingImageStore = IncomingImageStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(settingsStore)
                .environment(incomingImageStore)
                .onOpenURL { url in
                    Task {
                        guard url.isFileURL else { return }
                        // Photos hands us a file URL; access may be security-scoped.
                        let accessed = url.startAccessingSecurityScopedResource()
                        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                        guard let data = try? Data(contentsOf: url),
                              let image = UIImage(data: data) else { return }
                        incomingImageStore.pendingImages = [image]
                    }
                }
        }
    }
}
