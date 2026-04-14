//
//  ExportViewUITests.swift
//  image-incognitoUITests
//
//  UI tests for the Export screen: preview, settings toggles,
//  save/share buttons, and completion badge.
//  Navigates via Editor export action with --uitesting stub.
//

import XCTest

final class ExportViewUITests: XCTestCase {

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

    /// Navigates from Editor to Export by tapping the export button.
    private func navigateToExport() {
        let exportButton = app.buttons["editor.exportButton"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: UITestTimeout.long), "Editor should load via stub injection")

        // Wait for detection to complete before exporting
        // Detection on Simulator with blank stub is fast
        sleep(2)

        exportButton.tap()

        let backButton = app.buttons["export.backButton"]
        XCTAssertTrue(backButton.waitForExistence(timeout: UITestTimeout.long), "ExportView should appear after export")
    }

    // MARK: - Element Existence

    func testExportScreenElementsExist() throws {
        navigateToExport()

        XCTAssertTrue(app.buttons["export.backButton"].exists, "Back button should exist")
        XCTAssertTrue(app.staticTexts["export.title"].exists, "Title should exist")
        XCTAssertTrue(app.buttons["export.saveButton"].exists, "Save button should exist")
        XCTAssertTrue(app.buttons["export.shareButton"].exists, "Share button should exist")
    }

    // MARK: - Back Navigation

    func testBackButtonReturnsToEditor() throws {
        navigateToExport()

        app.buttons["export.backButton"].tap()

        let editorCancel = app.buttons["editor.cancelButton"]
        XCTAssertTrue(editorCancel.waitForExistence(timeout: UITestTimeout.standard), "Should return to EditorView")
    }

    // MARK: - Toggles

    func testToggleDefaultStates() throws {
        navigateToExport()

        // All toggles should be ON by default (ExportSettings defaults)
        let removeLocationToggle = app.switches["export.removeLocationToggle"]
        let removeExifToggle = app.switches["export.removeExifToggle"]
        let keepResolutionToggle = app.switches["export.keepResolutionToggle"]

        XCTAssertTrue(removeLocationToggle.waitForExistence(timeout: UITestTimeout.standard))
        XCTAssertTrue(removeExifToggle.exists)
        XCTAssertTrue(keepResolutionToggle.exists)

        // Check toggle values (value is "1" for ON, "0" for OFF)
        XCTAssertEqual(removeLocationToggle.value as? String, "1", "Remove location should be ON by default")
        XCTAssertEqual(removeExifToggle.value as? String, "1", "Remove EXIF should be ON by default")
        XCTAssertEqual(keepResolutionToggle.value as? String, "1", "Keep resolution should be ON by default")
    }

    func testToggleInteraction() throws {
        navigateToExport()

        let removeLocationToggle = app.switches["export.removeLocationToggle"]
        XCTAssertTrue(removeLocationToggle.waitForExistence(timeout: UITestTimeout.standard))

        // Toggle OFF
        removeLocationToggle.tap()
        XCTAssertEqual(removeLocationToggle.value as? String, "0", "Remove location should be OFF after tap")

        // Toggle back ON
        removeLocationToggle.tap()
        XCTAssertEqual(removeLocationToggle.value as? String, "1", "Remove location should be ON after second tap")
    }

    // MARK: - Completion Badge

    func testCompletionBadgeExists() throws {
        navigateToExport()

        let badge = app.staticTexts["export.completionBadge"]
        XCTAssertTrue(badge.waitForExistence(timeout: UITestTimeout.standard), "Completion badge should exist")
    }

    // MARK: - Dimension Label

    func testDimensionLabelExists() throws {
        navigateToExport()

        let dimensionLabel = app.staticTexts["export.dimensionLabel"]
        XCTAssertTrue(dimensionLabel.waitForExistence(timeout: UITestTimeout.standard), "Dimension label should exist")
    }
}
