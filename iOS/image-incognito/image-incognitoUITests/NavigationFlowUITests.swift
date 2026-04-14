//
//  NavigationFlowUITests.swift
//  image-incognitoUITests
//
//  End-to-end navigation flow tests verifying screen transitions
//  across the full app: Home → Editor → Export and back.
//

import XCTest

final class NavigationFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Full Happy Path

    func testFullHappyPath() throws {
        // Stub injection should auto-navigate to Editor
        let exportButton = app.buttons["editor.exportButton"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: UITestTimeout.long), "Should arrive at EditorView")

        // Wait for detection to complete
        sleep(2)

        // Tap export
        exportButton.tap()

        // Verify Export screen
        let saveButton = app.buttons["export.saveButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: UITestTimeout.long), "Should arrive at ExportView")
        XCTAssertTrue(app.staticTexts["export.completionBadge"].exists, "Completion badge should show")
    }

    // MARK: - Home ↔ Settings

    func testHomeToSettingsAndBack() throws {
        // Navigate back to Home first
        let cancelButton = app.buttons["editor.cancelButton"]
        if cancelButton.waitForExistence(timeout: UITestTimeout.standard) {
            cancelButton.tap()
        }

        // Open settings
        let settingsButton = app.buttons["home.settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: UITestTimeout.standard))
        settingsButton.tap()

        // Verify settings
        let closeButton = app.buttons["settings.closeButton"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: UITestTimeout.standard))

        // Close settings
        closeButton.tap()

        // Verify back on Home
        let heroCard = app.otherElements["home.heroCard"]
        XCTAssertTrue(heroCard.waitForExistence(timeout: UITestTimeout.standard), "Should be back on Home")
    }

    // MARK: - Editor ↔ Export

    func testEditorToExportAndBack() throws {
        // Should be on Editor via stub injection
        let exportButton = app.buttons["editor.exportButton"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: UITestTimeout.long))

        sleep(2) // Wait for detection

        exportButton.tap()

        // Verify Export
        let backButton = app.buttons["export.backButton"]
        XCTAssertTrue(backButton.waitForExistence(timeout: UITestTimeout.long))

        // Go back to Editor
        backButton.tap()

        // Verify Editor
        let editorCancel = app.buttons["editor.cancelButton"]
        XCTAssertTrue(editorCancel.waitForExistence(timeout: UITestTimeout.standard), "Should be back on EditorView")
    }

    // MARK: - Deep Navigation

    func testDeepNavigationBackToHome() throws {
        // Should be on Editor via stub injection
        let exportButton = app.buttons["editor.exportButton"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: UITestTimeout.long))

        sleep(2) // Wait for detection

        // Editor → Export
        exportButton.tap()
        let backButton = app.buttons["export.backButton"]
        XCTAssertTrue(backButton.waitForExistence(timeout: UITestTimeout.long))

        // Export → Editor
        backButton.tap()
        let cancelButton = app.buttons["editor.cancelButton"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: UITestTimeout.standard))

        // Editor → Home
        cancelButton.tap()
        let heroCard = app.otherElements["home.heroCard"]
        XCTAssertTrue(heroCard.waitForExistence(timeout: UITestTimeout.standard), "Should be back on Home after deep navigation")
    }
}
