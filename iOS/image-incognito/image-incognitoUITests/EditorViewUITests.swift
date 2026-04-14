//
//  EditorViewUITests.swift
//  image-incognitoUITests
//
//  UI tests for the Editor screen: face detection states,
//  masking style pills, sliders, and export button.
//  Requires --uitesting stub image injection.
//

import XCTest

final class EditorViewUITests: XCTestCase {

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

    // MARK: - Helpers

    /// Waits for EditorView to appear (stub injection pushes here automatically).
    private func waitForEditor() {
        let cancelButton = app.buttons["editor.cancelButton"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: UITestTimeout.long), "EditorView should appear via stub injection")
    }

    // MARK: - Element Existence

    func testEditorElementsExist() throws {
        waitForEditor()

        XCTAssertTrue(app.buttons["editor.cancelButton"].exists, "Cancel button should exist")
        XCTAssertTrue(app.buttons["editor.exportButton"].exists, "Export button should exist")
        XCTAssertTrue(app.otherElements["editor.imageCarousel"].exists, "Image carousel should exist")
    }

    // MARK: - Cancel

    func testCancelButtonDismisses() throws {
        waitForEditor()

        app.buttons["editor.cancelButton"].tap()

        let heroCard = app.otherElements["home.heroCard"]
        XCTAssertTrue(heroCard.waitForExistence(timeout: UITestTimeout.standard), "Should return to HomeView after cancel")
    }

    // MARK: - Detection State

    func testNoFaceFoundShown() throws {
        waitForEditor()

        // On Simulator with a blank stub image, VisionKit won't detect faces.
        // Wait for detection to complete and show "no face found".
        let noFaceView = app.otherElements["editor.noFaceFound"]
        XCTAssertTrue(noFaceView.waitForExistence(timeout: UITestTimeout.long), "No-face-found view should appear for blank stub image on Simulator")
    }

    // MARK: - Masking Style Pills

    func testMaskingStylePillsExist() throws {
        waitForEditor()

        XCTAssertTrue(app.buttons["editor.stylePill.blurredGlass"].waitForExistence(timeout: UITestTimeout.standard), "Blurred Glass pill should exist")
        XCTAssertTrue(app.buttons["editor.stylePill.pixelArt"].exists, "Pixel Art pill should exist")
        XCTAssertTrue(app.buttons["editor.stylePill.solidClean"].exists, "Solid Clean pill should exist")
    }

    func testStylePillSelection() throws {
        waitForEditor()

        let pixelArtPill = app.buttons["editor.stylePill.pixelArt"]
        XCTAssertTrue(pixelArtPill.waitForExistence(timeout: UITestTimeout.standard))
        pixelArtPill.tap()

        let solidCleanPill = app.buttons["editor.stylePill.solidClean"]
        solidCleanPill.tap()

        let blurredGlassPill = app.buttons["editor.stylePill.blurredGlass"]
        blurredGlassPill.tap()

        // If we get here without crash, style pill selection works
        XCTAssertTrue(blurredGlassPill.exists)
    }

    // MARK: - Export Button State

    func testExportButtonExists() throws {
        waitForEditor()

        let exportButton = app.buttons["editor.exportButton"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: UITestTimeout.standard), "Export button should be visible")
    }
}
