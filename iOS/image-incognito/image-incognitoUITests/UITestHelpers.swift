//
//  UITestHelpers.swift
//  image-incognitoUITests
//
//  Shared helpers for UI tests: app launch configuration,
//  element waiting utilities, and common assertions.
//

import XCTest

// MARK: - Timeouts

enum UITestTimeout {
    static let short: TimeInterval = 3
    static let standard: TimeInterval = 5
    static let long: TimeInterval = 10
}

// MARK: - XCUIApplication Helpers

extension XCUIApplication {

    /// Launches the app with the `--uitesting` flag.
    /// This skips Firebase init and injects stub images for Simulator testing.
    static func launchForTesting() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["--uitesting"]
        app.launch()
        return app
    }

    /// Launches the app in a clean state (no stub injection).
    static func launchClean() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["--uitesting"]
        // Reset UserDefaults so settings start fresh
        app.launchArguments += ["-com.image-incognito.exportSettings", ""]
        app.launch()
        return app
    }
}

// MARK: - XCUIElement Helpers

extension XCUIElement {

    /// Asserts that the element exists within the standard timeout.
    func assertExists(
        timeout: TimeInterval = UITestTimeout.standard,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            waitForExistence(timeout: timeout),
            "Expected \(identifier) to exist within \(timeout)s",
            file: file,
            line: line
        )
    }

    /// Asserts that the element does not exist.
    func assertNotExists(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(
            exists,
            "Expected \(identifier) to not exist",
            file: file,
            line: line
        )
    }
}
