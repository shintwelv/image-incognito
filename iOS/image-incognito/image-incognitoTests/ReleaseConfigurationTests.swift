//
//  ReleaseConfigurationTests.swift
//  image-incognitoTests
//
//  Release configuration checks that must stay aligned with App Store claims.
//

import Foundation
import Testing

@Suite("Release Configuration")
struct ReleaseConfigurationTests {

    private let repositoryRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    @Test("Privacy manifest declares only the UserDefaults reason used by the app")
    func privacyManifestMatchesRequiredReasonAPIs() throws {
        let manifestURL = repositoryRoot.appending(path: "iOS/image-incognito/image-incognito/PrivacyInfo.xcprivacy")
        let manifestData = try Data(contentsOf: manifestURL)
        let manifest = try #require(
            PropertyListSerialization.propertyList(from: manifestData, options: [], format: nil) as? [String: Any]
        )

        #expect(manifest["NSPrivacyTracking"] as? Bool == false)
        #expect((manifest["NSPrivacyCollectedDataTypes"] as? [Any])?.isEmpty == true)

        let accessedAPIs = try #require(manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        #expect(accessedAPIs.count == 1)

        let userDefaults = try #require(accessedAPIs.first {
            $0["NSPrivacyAccessedAPIType"] as? String == "NSPrivacyAccessedAPICategoryUserDefaults"
        })
        #expect(userDefaults["NSPrivacyAccessedAPITypeReasons"] as? [String] == ["CA92.1"])
    }

    @Test("Release project contains no Firebase configuration and uses the prepared version")
    func releaseProjectHasNoFirebaseAndUsesVersion171Build8() throws {
        let project = try sourceContents("iOS/image-incognito/image-incognito.xcodeproj/project.pbxproj")
        let appBootstrap = try sourceContents("iOS/image-incognito/image-incognito/image_incognitoApp.swift")

        for source in [project, appBootstrap] {
            #expect(!source.localizedCaseInsensitiveContains("firebase"))
            #expect(!source.localizedCaseInsensitiveContains("googleservice-info"))
        }

        let packageResolutionURL = repositoryRoot.appending(path: "iOS/image-incognito/image-incognito.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved")
        #expect(!FileManager.default.fileExists(atPath: packageResolutionURL.path))

        #expect(occurrences(of: "CURRENT_PROJECT_VERSION = 8;", in: project) == 6)
        #expect(occurrences(of: "MARKETING_VERSION = 1.7.1;", in: project) == 6)
    }

    @Test("All five release-note localizations describe version 1.7.1")
    func allReleaseNoteLocalizationsUseVersion171() throws {
        let metadata = try sourceContents("AppStoreSubmission/metadata.md")

        for locale in [
            "English (en-US)",
            "Korean (ko)",
            "Japanese (ja)",
            "Spanish (es)",
            "Simplified Chinese (zh-Hans)"
        ] {
            #expect(metadata.contains("Localization: \(locale)"))
        }

        #expect(metadata.contains("App Store Submission Materials (Version 1.7.1)"))
        #expect(metadata.contains("version 1.7.1 (Build 8)"))
        #expect(occurrences(of: "### What's New in Version 1.7.1", in: metadata) == 5)
        #expect(!metadata.contains("### What's New in Version 1.7\n"))
    }

    @Test("Shared test scheme excludes the empty UI test target")
    func sharedTestSchemeExcludesEmptyUITestTarget() throws {
        let scheme = try sourceContents("iOS/image-incognito/image-incognito.xcodeproj/xcshareddata/xcschemes/image-incognito.xcscheme")

        #expect(!scheme.contains("image-incognitoUITests.xctest"))
    }

    private func sourceContents(_ relativePath: String) throws -> String {
        try String(contentsOf: repositoryRoot.appending(path: relativePath), encoding: .utf8)
    }

    private func occurrences(of value: String, in source: String) -> Int {
        source.components(separatedBy: value).count - 1
    }
}
