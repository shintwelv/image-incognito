//
//  image_incognitoUITestsLaunchTests.swift
//  image-incognitoUITests
//
//  Launch performance and screenshot tests.
//

import XCTest

final class image_incognitoUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Launch Performance

    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments += ["--uitesting"]
            app.launch()
        }
    }

    // MARK: - Launch Screenshot

    func testLaunchScreenshot() throws {
        let app = XCUIApplication()
        app.launchArguments += ["--uitesting"]
        app.launch()

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
