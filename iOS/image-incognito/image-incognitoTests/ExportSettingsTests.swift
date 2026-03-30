//
//  ExportSettingsTests.swift
//  image-incognitoTests
//
//  Unit tests for ExportSettings Codable round-trips and default values.
//

import Testing
import Foundation
@testable import image_incognito

@Suite("ExportSettings")
struct ExportSettingsTests {

    @Test("Default values are all true")
    func defaults() {
        let settings = ExportSettings()

        #expect(settings.removeLocation == true)
        #expect(settings.removeExif == true)
        #expect(settings.keepOriginalResolution == true)
    }

    @Test("Codable round-trip preserves default values")
    func codableRoundTripDefaults() throws {
        let original = ExportSettings()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ExportSettings.self, from: data)

        #expect(decoded.removeLocation == original.removeLocation)
        #expect(decoded.removeExif == original.removeExif)
        #expect(decoded.keepOriginalResolution == original.keepOriginalResolution)
    }

    @Test("Codable round-trip preserves all-false values")
    func codableRoundTripAllFalse() throws {
        var settings = ExportSettings()
        settings.removeLocation = false
        settings.removeExif = false
        settings.keepOriginalResolution = false

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(ExportSettings.self, from: data)

        #expect(decoded.removeLocation == false)
        #expect(decoded.removeExif == false)
        #expect(decoded.keepOriginalResolution == false)
    }

    @Test("Codable round-trip preserves mixed values")
    func codableRoundTripMixed() throws {
        var settings = ExportSettings()
        settings.removeLocation = true
        settings.removeExif = false
        settings.keepOriginalResolution = true

        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(ExportSettings.self, from: data)

        #expect(decoded.removeLocation == true)
        #expect(decoded.removeExif == false)
        #expect(decoded.keepOriginalResolution == true)
    }
}
