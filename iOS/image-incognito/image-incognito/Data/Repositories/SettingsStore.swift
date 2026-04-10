//
//  SettingsStore.swift
//  image-incognito
//
//  Data Repository – App-wide settings container.
//  Persists ExportSettings to UserDefaults so they survive app termination.
//  Lives in the Data layer because UserDefaults is an infrastructure concern.
//

import Observation
import Foundation

@Observable
final class SettingsStore {

    private static let userDefaultsKey = "com.image-incognito.exportSettings"

    /// Default export options applied whenever a new export session starts.
    /// Any change is immediately written to UserDefaults.
    var exportSettings: ExportSettings {
        didSet { persist() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.userDefaultsKey),
           let decoded = try? JSONDecoder().decode(ExportSettings.self, from: data) {
            exportSettings = decoded
        } else {
            exportSettings = ExportSettings()
        }
    }

    // MARK: - Private

    private func persist() {
        guard let data = try? JSONEncoder().encode(exportSettings) else { return }
        UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
    }
}
