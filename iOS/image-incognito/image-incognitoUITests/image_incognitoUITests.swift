//
//  image_incognitoUITests.swift
//  image-incognitoUITests
//
//  Base test file. Individual screen tests are in separate files:
//  - HomeViewUITests.swift
//  - EditorViewUITests.swift
//  - ExportViewUITests.swift
//  - SettingsViewUITests.swift
//  - NavigationFlowUITests.swift
//

import XCTest

final class image_incognitoUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {}

    /// Smoke test: app launches without crashing.
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launchArguments += ["--uitesting"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: UITestTimeout.standard))
    }
}
