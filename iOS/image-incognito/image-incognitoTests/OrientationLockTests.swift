//
//  OrientationLockTests.swift
//  image-incognitoTests
//
//  Regression checks for the portrait-only orientation lock.
//

import Testing
import UIKit
@testable import image_incognito

#if targetEnvironment(simulator)
// The Info.plist check inspects the repository via `#filePath`, which a
// physical-device test bundle cannot access. Keep this suite on Simulator,
// matching the ReleaseConfigurationTests host-filesystem pattern.
@MainActor
@Suite("Orientation Lock")
struct OrientationLockTests {

    private let repositoryRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    @Test("Info.plist supports portrait only on iPhone and iPad")
    func infoPlistSupportsPortraitOnly() throws {
        let plistURL = repositoryRoot.appending(path: "iOS/image-incognito/Info.plist")
        let plistData = try Data(contentsOf: plistURL)
        let plist = try #require(
            PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any]
        )

        #expect(plist["UISupportedInterfaceOrientations"] as? [String] == ["UIInterfaceOrientationPortrait"])
        #expect(plist["UISupportedInterfaceOrientations~ipad"] as? [String] == ["UIInterfaceOrientationPortrait"])
        #expect(plist["UIRequiresFullScreen"] as? Bool == true)
    }

    @Test("AppDelegate restricts supported orientations to portrait")
    func appDelegateRestrictsToPortrait() {
        let delegate = AppDelegate()
        let orientations = delegate.application(UIApplication.shared, supportedInterfaceOrientationsFor: nil)

        #expect(orientations == .portrait)
    }

    @Test("Portrait lock updates only non-portrait scene geometry")
    func portraitLockRequestsUpdateOnlyWhenNeeded() {
        #expect(PortraitLockController.needsPortraitUpdate(current: .portrait) == false)
        #expect(PortraitLockController.needsPortraitUpdate(current: .landscapeLeft))
        #expect(PortraitLockController.needsPortraitUpdate(current: .landscapeRight))
        #expect(PortraitLockController.needsPortraitUpdate(current: .portraitUpsideDown))
    }
}
#endif
