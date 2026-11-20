//
//  DeviceReviewFlowUITests.swift
//  image-incognitoUITests
//
//  Device smoke tests for the manual masking flow: draw, confirm, export.
//  Launched with `--uitesting`, which injects a stub image and opens Editor.
//

import XCTest

final class DeviceReviewFlowUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait

        app = XCUIApplication()
        app.launchArguments += [
            "--uitesting",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.orientation = .portrait
        app = nil
    }

    // MARK: - Tests

    func testConfirmWithoutRegionsShowsWarningAndStaysInEditor() {
        launchToEditor()

        let confirm = app.buttons["editor.confirmButton"]
        waitUntilEnabled(confirm)
        confirm.tap()

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "Zero-region confirm should show a warning alert")
        XCTAssertTrue(alert.staticTexts["Nothing to hide"].exists)

        alert.buttons["Go back"].tap()

        XCTAssertTrue(app.buttons["editor.addRegion"].waitForExistence(timeout: 5), "Editor should remain after dismissing the warning")
        XCTAssertFalse(app.staticTexts["export.title"].exists)
    }

    func testManualRectangleDrawConfirmAndExport() {
        launchToEditor()

        addRegion()
        drawManualRegion()
        assertAdjustmentPanelVisible()

        let confirm = app.buttons["editor.confirmButton"]
        waitUntilEnabled(confirm)
        confirm.tap()

        assertExportReached()
        app.buttons["export.backButton"].tap()
        XCTAssertTrue(app.buttons["editor.addRegion"].waitForExistence(timeout: 10), "Editor should be reachable from Export")
    }

    func testCircleAndEllipseShapePickersReachExport() {
        launchToEditor()

        // Circle → draw → export.
        addRegion()
        selectShape("circle")
        drawManualRegion()
        assertAdjustmentPanelVisible()

        let confirm = app.buttons["editor.confirmButton"]
        waitUntilEnabled(confirm)
        confirm.tap()
        assertExportReached()
        app.buttons["export.backButton"].tap()
        XCTAssertTrue(app.buttons["editor.addRegion"].waitForExistence(timeout: 10))

        // Ellipse → draw → adjustment panel.
        addRegion()
        selectShape("ellipse")
        drawManualRegion()
        assertAdjustmentPanelVisible()
    }

    func testDiscardProtectionKeepsDraftRegion() {
        launchToEditor()

        addRegion()
        drawManualRegion()
        assertAdjustmentPanelVisible()

        app.buttons["editor.cancelButton"].tap()

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "Back should warn about discarding a draft")
        XCTAssertTrue(alert.staticTexts["Discard changes?"].exists)

        alert.buttons["Keep editing"].tap()

        XCTAssertTrue(element("editor.adjustmentPanel").waitForExistence(timeout: 5), "Draft region should remain after Keep editing")
        XCTAssertTrue(app.buttons["editor.addRegion"].exists)
    }

    func testLandscapeManualDrawConfirmAndExport() {
        XCUIDevice.shared.orientation = .landscapeLeft
        launchToEditor()

        addRegion()
        drawManualRegion()
        assertAdjustmentPanelVisible()

        let confirm = app.buttons["editor.confirmButton"]
        waitUntilEnabled(confirm)
        confirm.tap()

        assertExportReached()
    }

    // MARK: - Flow helpers

    private func launchToEditor() {
        app.launch()

        let addRegion = app.buttons["editor.addRegion"]
        XCTAssertTrue(
            addRegion.waitForExistence(timeout: 20),
            "Editor did not appear within 20s (stub image injection or navigation failed)"
        )
        waitUntilEnabled(app.buttons["editor.confirmButton"])
    }

    private func addRegion() {
        let addRegion = app.buttons["editor.addRegion"]
        waitUntilEnabled(addRegion)
        addRegion.tap()

        let overlay = element("editor.drawOverlay")
        XCTAssertTrue(overlay.waitForExistence(timeout: 10), "Drawing overlay did not appear")
    }

    private func selectShape(_ shape: String) {
        // The identifier sits on a StylePill wrapper, which surfaces as an
        // "Other" element rather than a button in the accessibility tree.
        let picker = element("editor.shapePicker.\(shape)")
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "Shape picker \(shape) missing")
        picker.tap()
    }

    /// Drags inside the photo canvas. The carousel frame equals the canvas, so
    /// normalized offsets stay inside the rendered image on iPhone and iPad.
    private func drawManualRegion() {
        let canvas = element("editor.imageCarousel")
        XCTAssertTrue(canvas.waitForExistence(timeout: 5), "Image canvas missing")

        let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.45, dy: 0.70))
        let end = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.85))
        start.press(forDuration: 0.2, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.3)
    }

    private func assertAdjustmentPanelVisible() {
        XCTAssertTrue(
            element("editor.adjustmentPanel").waitForExistence(timeout: 10),
            "Adjustment panel should appear after drawing a manual region"
        )

        let region = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'editor.regionOverlay.'"))
            .firstMatch
        XCTAssertTrue(region.waitForExistence(timeout: 5), "Drawn region overlay missing")
    }

    private func assertExportReached() {
        let title = element("export.title")
        XCTAssertTrue(title.waitForExistence(timeout: 30), "Export screen did not appear within 30s")
        XCTAssertTrue(element("export.previewImage").waitForExistence(timeout: 5), "Export preview missing")
    }

    // MARK: - Element helpers

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func waitUntilEnabled(
        _ element: XCUIElement,
        timeout: TimeInterval = 30,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate(format: "enabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "\(element) did not become enabled within \(timeout)s",
            file: file,
            line: line
        )
    }
}
