//
//  ReleaseConfigurationTests.swift
//  image-incognitoTests
//
//  Release configuration checks that must stay aligned with App Store claims.
//

import Foundation
import Testing

#if targetEnvironment(simulator) || os(macOS)
// These checks deliberately inspect files in the repository using `#filePath`.
// A physical-device test bundle cannot access that host filesystem, so retain
// this release-audit suite on Simulator and macOS test hosts only.
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
    func releaseProjectHasNoFirebaseAndUsesVersion180Build10() throws {
        let project = try sourceContents("iOS/image-incognito/image-incognito.xcodeproj/project.pbxproj")
        let appBootstrap = try sourceContents("iOS/image-incognito/image-incognito/image_incognitoApp.swift")

        for source in [project, appBootstrap] {
            #expect(!source.localizedCaseInsensitiveContains("firebase"))
            #expect(!source.localizedCaseInsensitiveContains("googleservice-info"))
        }

        let packageResolutionURL = repositoryRoot.appending(path: "iOS/image-incognito/image-incognito.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved")
        #expect(!FileManager.default.fileExists(atPath: packageResolutionURL.path))

        #expect(occurrences(of: "CURRENT_PROJECT_VERSION = 10;", in: project) == 6)
        #expect(occurrences(of: "MARKETING_VERSION = 1.8.0;", in: project) == 6)
    }

    @Test("All five release-note localizations describe version 1.8.0")
    func allReleaseNoteLocalizationsUseVersion180() throws {
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

        #expect(metadata.contains("App Store Submission Materials (Version 1.8.0)"))
        #expect(metadata.contains("version 1.8.0 (Build 10)"))
        #expect(occurrences(of: "### What's New in Version 1.8.0", in: metadata) == 5)
        #expect(!metadata.contains("### What's New in Version 1.7.1"))
    }

    @Test("Shared test scheme excludes the empty UI test target")
    func sharedTestSchemeExcludesEmptyUITestTarget() throws {
        let scheme = try sourceContents("iOS/image-incognito/image-incognito.xcodeproj/xcshareddata/xcschemes/image-incognito.xcscheme")

        #expect(!scheme.contains("image-incognitoUITests.xctest"))
    }

    @Test("App source and store keywords contain no OCR or license-plate remnants")
    func appSourceContainsNoTextDetectionRemnants() throws {
        let appSourceRoot = repositoryRoot.appending(path: "iOS/image-incognito/image-incognito")
        let swiftFiles = try FileManager.default
            .subpathsOfDirectory(atPath: appSourceRoot.path)
            .filter { $0.hasSuffix(".swift") }
            .sorted()

        #expect(!swiftFiles.isEmpty)

        let bannedTokens = ["VNRecognizeTextRequest", "includeText", "licensePlate", "textRedact"]
        for relativePath in swiftFiles {
            let source = try sourceContents("iOS/image-incognito/image-incognito/\(relativePath)")
            for token in bannedTokens {
                #expect(
                    !source.contains(token),
                    "App source \(relativePath) contains banned OCR token \(token)"
                )
            }
        }

        // Only the App Store keyword blocks must avoid advertising OCR features.
        // Release notes may legitimately mention that plate/text detection was removed.
        let metadata = try sourceContents("AppStoreSubmission/metadata.md")
        let keywordBlocks = keywordBlocks(in: metadata)
        #expect(keywordBlocks.count == 5, "Expected one Keywords block per locale")
        #expect(keywordBlocks.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })

        let keywords = keywordBlocks.joined(separator: "\n").lowercased()
        #expect(!keywords.contains("license plate"))
        #expect(!keywords.contains("text redact"))
    }

    /// Returns the body of each `### Keywords` section in a Markdown document.
    private func keywordBlocks(in markdown: String) -> [String] {
        var blocks: [String] = []
        var current: [String] = []
        var isCollecting = false

        func finishBlock() {
            if isCollecting {
                blocks.append(current.joined(separator: "\n"))
                current = []
                isCollecting = false
            }
        }

        for line in markdown.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "### Keywords" {
                finishBlock()
                isCollecting = true
            } else if isCollecting && (trimmed.hasPrefix("### ") || trimmed == "---") {
                finishBlock()
            } else if isCollecting {
                current.append(line)
            }
        }
        finishBlock()
        return blocks
    }

    private func sourceContents(_ relativePath: String) throws -> String {
        try String(contentsOf: repositoryRoot.appending(path: relativePath), encoding: .utf8)
    }

    private func occurrences(of value: String, in source: String) -> Int {
        source.components(separatedBy: value).count - 1
    }
}
#endif
