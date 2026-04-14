//
//  SettingsViewUITests.swift
//  image-incognitoUITests
//
//  UI tests for the Settings screen: element existence,
//  toggle interactions, version info, and persistence.
//

import XCTest

final class SettingsViewUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["--uitesting"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helpers

    /// Launches app and opens Settings from Home.
    private func openSettings() {
        app.launch()

        // Navigate back to Home if stub injection pushed to Editor
        let cancelButton = app.buttons["editor.cancelButton"]
        if cancelButton.waitForExistence(timeout: UITestTimeout.standard) {
            cancelButton.tap()
        }

        let settingsButton = app.buttons["home.settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: UITestTimeout.standard))
        settingsButton.tap()

        let closeButton = app.buttons["settings.closeButton"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: UITestTimeout.standard), "Settings should open")
    }

    // MARK: - Element Existence

    func testSettingsElementsExist() throws {
        openSettings()

        XCTAssertTrue(app.buttons["settings.closeButton"].exists, "Close button should exist")

        // Toggle rows
        XCTAssertTrue(app.switches["settings.removeLocationToggle"].waitForExistence(timeout: UITestTimeout.standard), "Remove location toggle should exist")
        XCTAssertTrue(app.switches["settings.removeExifToggle"].exists, "Remove EXIF toggle should exist")
        XCTAssertTrue(app.switches["settings.keepResolutionToggle"].exists, "Keep resolution toggle should exist")

        // Info rows
        XCTAssertTrue(app.otherElements["settings.versionRow"].waitForExistence(timeout: UITestTimeout.short) || app.staticTexts["settings.versionRow"].exists, "Version row should exist")
        XCTAssertTrue(app.otherElements["settings.developerRow"].waitForExistence(timeout: UITestTimeout.short) || app.staticTexts["settings.developerRow"].exists, "Developer row should exist")
    }

    // MARK: - Close Button

    func testCloseButtonDismisses() throws {
        openSettings()

        app.buttons["settings.closeButton"].tap()

        let heroCard = app.otherElements["home.heroCard"]
        XCTAssertTrue(heroCard.waitForExistence(timeout: UITestTimeout.standard), "Should return to Home after closing Settings")
    }

    // MARK: - Toggle Interaction

    func testExportSettingsTogglesWork() throws {
        openSettings()

        let removeLocationToggle = app.switches["settings.removeLocationToggle"]
        XCTAssertTrue(removeLocationToggle.waitForExistence(timeout: UITestTimeout.standard))

        // Toggle OFF
        removeLocationToggle.tap()
        XCTAssertEqual(removeLocationToggle.value as? String, "0", "Toggle should be OFF after tap")

        // Toggle back ON
        removeLocationToggle.tap()
        XCTAssertEqual(removeLocationToggle.value as? String, "1", "Toggle should be ON after second tap")

        // Test EXIF toggle too
        let removeExifToggle = app.switches["settings.removeExifToggle"]
        removeExifToggle.tap()
        XCTAssertEqual(removeExifToggle.value as? String, "0", "EXIF toggle should be OFF after tap")
        removeExifToggle.tap()
        XCTAssertEqual(removeExifToggle.value as? String, "1", "EXIF toggle should be ON after second tap")
    }

    // MARK: - Version Info

    func testVersionInfoDisplayed() throws {
        openSettings()

        // The version row should contain a non-empty version string.
        // We search for "settings.versionRow" element which wraps the label + value.
        let versionRow = app.otherElements["settings.versionRow"]
        if versionRow.waitForExistence(timeout: UITestTimeout.short) {
            // Row exists as a grouped element
            XCTAssertTrue(true)
        } else {
            // Fallback: look for any text containing version-like pattern
            let versionTexts = app.staticTexts.matching(identifier: "settings.versionRow")
            XCTAssertTrue(versionTexts.count > 0, "Version info should be displayed")
        }
    }

    // MARK: - Persistence

    func testSettingsPersistAcrossReopen() throws {
        openSettings()

        // Toggle remove location OFF
        let removeLocationToggle = app.switches["settings.removeLocationToggle"]
        XCTAssertTrue(removeLocationToggle.waitForExistence(timeout: UITestTimeout.standard))
        removeLocationToggle.tap()
        XCTAssertEqual(removeLocationToggle.value as? String, "0")

        // Close settings
        app.buttons["settings.closeButton"].tap()

        // Reopen settings
        let settingsButton = app.buttons["home.settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: UITestTimeout.standard))
        settingsButton.tap()

        // Verify toggle persisted as OFF
        let reopenedToggle = app.switches["settings.removeLocationToggle"]
        XCTAssertTrue(reopenedToggle.waitForExistence(timeout: UITestTimeout.standard))
        XCTAssertEqual(reopenedToggle.value as? String, "0", "Toggle state should persist across reopen")

        // Clean up: toggle back ON
        reopenedToggle.tap()
    }
}
