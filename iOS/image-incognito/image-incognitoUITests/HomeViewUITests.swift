//
//  HomeViewUITests.swift
//  image-incognitoUITests
//
//  UI tests for the Home screen: element existence, navigation to
//  Settings/PhotoPicker/Camera, and recent section visibility.
//

import XCTest

final class HomeViewUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["--uitesting"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Element Existence

    func testHomeScreenElementsExist() throws {
        // Launch clean (don't inject stub images so we stay on Home)
        app.launch()

        // Wait for the stub image navigation to possibly trigger, then go back if needed
        let cancelButton = app.buttons["editor.cancelButton"]
        if cancelButton.waitForExistence(timeout: UITestTimeout.standard) {
            cancelButton.tap()
        }

        let heroCard = app.otherElements["home.heroCard"]
        XCTAssertTrue(heroCard.waitForExistence(timeout: UITestTimeout.standard), "Hero card should be visible")

        let selectPhotosButton = app.buttons["home.selectPhotosButton"]
        XCTAssertTrue(selectPhotosButton.exists, "Select Photos button should be visible")

        let cameraButton = app.buttons["home.cameraButton"]
        XCTAssertTrue(cameraButton.exists, "Camera button should be visible")

        let settingsButton = app.buttons["home.settingsButton"]
        XCTAssertTrue(settingsButton.exists, "Settings button should be visible")
    }

    // MARK: - Settings Sheet

    func testSettingsSheetOpens() throws {
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
        XCTAssertTrue(closeButton.waitForExistence(timeout: UITestTimeout.standard), "Settings sheet should appear")
    }

    func testSettingsSheetCloses() throws {
        app.launch()

        let cancelButton = app.buttons["editor.cancelButton"]
        if cancelButton.waitForExistence(timeout: UITestTimeout.standard) {
            cancelButton.tap()
        }

        let settingsButton = app.buttons["home.settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: UITestTimeout.standard))
        settingsButton.tap()

        let closeButton = app.buttons["settings.closeButton"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: UITestTimeout.standard))
        closeButton.tap()

        // Verify settings dismissed — hero card should be visible again
        let heroCard = app.otherElements["home.heroCard"]
        XCTAssertTrue(heroCard.waitForExistence(timeout: UITestTimeout.standard), "Should return to Home after closing Settings")
    }

    // MARK: - Photo Picker

    func testPhotoPickerSheetOpens() throws {
        app.launch()

        let cancelButton = app.buttons["editor.cancelButton"]
        if cancelButton.waitForExistence(timeout: UITestTimeout.standard) {
            cancelButton.tap()
        }

        let selectPhotosButton = app.buttons["home.selectPhotosButton"]
        XCTAssertTrue(selectPhotosButton.waitForExistence(timeout: UITestTimeout.standard))
        selectPhotosButton.tap()

        // PHPicker presents a system navigation bar with "Cancel"
        let pickerCancel = app.buttons["Cancel"]
        XCTAssertTrue(pickerCancel.waitForExistence(timeout: UITestTimeout.standard), "PHPicker should appear with Cancel button")
        pickerCancel.tap()
    }

    // MARK: - Camera (Simulator Skip)

    func testCameraFullScreenCoverOpens() throws {
        try XCTSkipIf(true, "Camera is not available on Simulator")
    }

    // MARK: - Recent Section

    func testRecentSectionHiddenWhenEmpty() throws {
        app.launch()

        let cancelButton = app.buttons["editor.cancelButton"]
        if cancelButton.waitForExistence(timeout: UITestTimeout.standard) {
            cancelButton.tap()
        }

        let recentTitle = app.staticTexts["home.recentSectionTitle"]
        XCTAssertFalse(recentTitle.exists, "Recent section should be hidden when there are no recent items")
    }
}
