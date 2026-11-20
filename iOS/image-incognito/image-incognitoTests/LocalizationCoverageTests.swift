//
//  LocalizationCoverageTests.swift
//  image-incognitoTests
//
//  Guards the String Catalog contract: Korean source language, five supported
//  locales, and non-empty translations for every editor/export/home key.
//

import Foundation
import Testing

#if targetEnvironment(simulator) || os(macOS)
@Suite("Localization Coverage")
struct LocalizationCoverageTests {

    private static let supportedLocales = ["en", "ko", "ja", "es", "zh-Hans"]

    private static let requiredKeys: [String] = [
        // Editor – review workspace
        "editor.review.title",
        "editor.review.subtitle",
        "editor.review.analyzingAll",
        "editor.addRegion",
        "editor.shape.title",
        "editor.shape.rectangle",
        "editor.shape.circle",
        "editor.shape.ellipse",
        "editor.shape.switchHint",
        "editor.draw.instruction",
        "editor.draw.cancel",
        "editor.draw.tooSmall",
        "editor.regionLimit.reached",
        "editor.region.included",
        "editor.region.excluded",
        "editor.region.include",
        "editor.region.exclude",
        "editor.region.delete",
        "editor.region.deleteToast",
        "editor.region.manual",
        "editor.region.face",
        "editor.region.selected",
        "editor.region.resizeHandle",
        "editor.region.handlesHint",
        "editor.style.applyToAll",
        "editor.style.appliedToAll",
        "editor.style.selectRegionFirst",
        "editor.confirm",
        "editor.confirm.multi",
        "editor.confirmEmpty.title",
        "editor.confirmEmpty.message",
        "editor.confirmEmpty.back",
        "editor.confirmEmpty.exportOriginal",
        "editor.confirmPartial.title",
        "editor.confirmPartial.message",
        "editor.confirmPartial.continue",
        "editor.noFaceFound.title",
        "editor.noFaceFound.message",
        "editor.noFaceFound.addRegion",
        "editor.detectionFailed.title",
        "editor.detectionFailed.message",
        "editor.detectionFailed.addRegion",
        "editor.rendering.progress",
        "editor.rendering.failed",
        "editor.rendering.retry",
        "editor.rendering.short",
        "editor.pageIndicator.accessibility",
        "editor.regionList.title",
        "editor.regionList.empty",
        "editor.regionList.close",
        "editor.discard.title",
        "editor.discard.message",
        "editor.discard.leave",
        "editor.discard.keepEditing",
        // Export
        "export.maskedAreas",
        "export.maskedAreas.zero",
        "export.title",
        "export.backButton",
        "export.compareHint",
        "export.saveFailed",
        // Home
        "home.hero.subtitle",
        "home.hero.steps",
        // Shared
        "common.cancel",
        "common.ok"
    ]

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func loadCatalog() throws -> [String: Any] {
        let url = repositoryRoot
            .appending(path: "iOS/image-incognito/image-incognito/Localizable.xcstrings")
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data)
        return try #require(json as? [String: Any])
    }

    @Test("Catalog is Korean-sourced")
    func catalogSourceLanguageIsKorean() throws {
        let catalog = try loadCatalog()
        #expect(catalog["sourceLanguage"] as? String == "ko")
    }

    @Test("Representative copy keeps Korean as the source language")
    func representativeCopyMatchesSourceLanguage() throws {
        let catalog = try loadCatalog()
        let strings = try #require(catalog["strings"] as? [String: Any])

        let expectations: [String: (korean: String, english: String)] = [
            "editor.review.title": ("1/2 확인", "1/2 Review"),
            "editor.confirm": ("가리기 %d곳", "Hide %d"),
            "editor.discard.title": ("편집 내용을 버릴까요?", "Discard changes?"),
            "export.title": ("2/2 미리보기", "2/2 Preview"),
            "export.backButton": ("다시 편집", "Edit areas"),
            "home.hero.subtitle": ("AI가 얼굴을 찾고, 가릴 곳은 직접 정하세요.", "AI finds faces. You decide what to hide."),
            "home.hero.steps": ("사진 선택 → 얼굴/영역 확인 → 미리보기 & 저장", "Pick photos → Review faces and areas → Preview and save")
        ]

        for (key, expected) in expectations {
            let entry = try #require(strings[key] as? [String: Any], "Missing key: \(key)")
            let localizations = try #require(entry["localizations"] as? [String: Any])
            let korean = try #require(localizations["ko"] as? [String: Any])
            let english = try #require(localizations["en"] as? [String: Any])
            let koreanUnit = try #require(korean["stringUnit"] as? [String: Any])
            let englishUnit = try #require(english["stringUnit"] as? [String: Any])
            #expect(koreanUnit["value"] as? String == expected.korean, "Korean value changed: \(key)")
            #expect(englishUnit["value"] as? String == expected.english, "English value changed: \(key)")
        }
    }

    @Test("Editor, export, and home keys are translated in all five locales")
    func requiredKeysHaveCompleteTranslations() throws {
        let catalog = try loadCatalog()
        let strings = try #require(catalog["strings"] as? [String: Any])

        for key in Self.requiredKeys {
            let entry = try #require(strings[key] as? [String: Any], "Missing key: \(key)")
            let localizations = try #require(
                entry["localizations"] as? [String: Any],
                "Missing localizations: \(key)"
            )

            for locale in Self.supportedLocales {
                let localization = try #require(
                    localizations[locale] as? [String: Any],
                    "Missing \(locale) translation: \(key)"
                )
                let stringUnit = try #require(
                    localization["stringUnit"] as? [String: Any],
                    "Missing stringUnit for \(locale): \(key)"
                )
                let value = (stringUnit["value"] as? String ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                #expect(!value.isEmpty, "Empty \(locale) translation: \(key)")
            }
        }
    }
}
#endif
