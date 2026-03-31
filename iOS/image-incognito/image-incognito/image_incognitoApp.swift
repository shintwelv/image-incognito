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

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(settingsStore)
        }
    }
}
