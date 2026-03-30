//
//  SettingsStoreTests.swift
//  image-incognitoTests
//
//  Unit tests for SettingsStore: UserDefaults persistence and default values.
//  Run serially to avoid concurrent access to UserDefaults.
//

import Testing
import Foundation
@testable import image_incognito

@Suite("SettingsStore", .serialized)
struct SettingsStoreTests {

    private static let key = "com.image-incognito.exportSettings"

    private func clearDefaults() {
        UserDefaults.standard.removeObject(forKey: Self.key)
    }

    @Test("Creates default settings when UserDefaults is empty")
    func defaultSettings() {
        clearDefaults()
        defer { clearDefaults() }

        let store = SettingsStore()

        #expect(store.exportSettings.removeLocation == true)
        #expect(store.exportSettings.removeExif == true)
        #expect(store.exportSettings.keepOriginalResolution == true)
    }

    @Test("Persists changed settings to UserDefaults immediately")
    func persistsOnChange() throws {
        clearDefaults()
        defer { clearDefaults() }

        let store = SettingsStore()
        store.exportSettings.removeLocation = false
        store.exportSettings.removeExif = false

        let data = try #require(UserDefaults.standard.data(forKey: Self.key))
        let saved = try JSONDecoder().decode(ExportSettings.self, from: data)

        #expect(saved.removeLocation == false)
        #expect(saved.removeExif == false)
        #expect(saved.keepOriginalResolution == true)
    }

    @Test("New instance restores previously persisted settings")
    func restoresPersisted() {
        clearDefaults()
        defer { clearDefaults() }

        let store1 = SettingsStore()
        store1.exportSettings.removeLocation = false
        store1.exportSettings.keepOriginalResolution = false

        let store2 = SettingsStore()

        #expect(store2.exportSettings.removeLocation == false)
        #expect(store2.exportSettings.removeExif == true)
        #expect(store2.exportSettings.keepOriginalResolution == false)
    }

    @Test("Overwriting settings persists the latest value")
    func persistsLatestValue() {
        clearDefaults()
        defer { clearDefaults() }

        let store = SettingsStore()
        store.exportSettings.removeLocation = false
        store.exportSettings.removeLocation = true  // overwrite back

        let store2 = SettingsStore()
        #expect(store2.exportSettings.removeLocation == true)
    }
}
