//
//  image_incognitoApp.swift
//  image-incognito
//
//  Created by elvin on 3/27/26.
//

import SwiftUI

@main
struct image_incognitoApp: App {

    @State private var settingsStore = SettingsStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(settingsStore)
        }
    }
}
