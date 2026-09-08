import sys
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPTS_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPTS_DIR))

import upload_metadata_api as uploader


class AppInfoLocalizationSubtitlePayloadTests(unittest.TestCase):
    subtitles = {
        "en-US": "Auto Face Privacy for Photos",
        "ko": "자동 얼굴 프라이버시 보호",
        "ja": "写真の自動顔プライバシー保護",
        "es-ES": "Privacidad facial automática",
        "zh-Hans": "照片人脸自动隐私保护",
    }

    def test_sync_emits_all_subtitles_through_app_info_localizations(self):
        locales_metadata = {
            locale: {
                "subtitle": subtitle,
                "description": f"Description for {locale}",
                "keywords": f"keywords for {locale}",
                "whatsNew": f"What's new for {locale}",
                "promotionalText": f"Promotion for {locale}",
                "supportUrl": "https://example.com/support",
                "marketingUrl": "https://example.com/marketing",
            }
            for locale, subtitle in self.subtitles.items()
        }
        version_localization_ids = {
            locale: f"version-localization-{locale}" for locale in self.subtitles
        }
        app_info_localization_ids = {
            locale: f"app-info-localization-{locale}" for locale in self.subtitles
        }
        calls = []

        def fake_api_request(url, method="GET", body=None):
            calls.append({"url": url, "method": method, "body": body})

            if (
                url
                == f"https://api.appstoreconnect.apple.com/v1/apps/{uploader.APP_ID}/appStoreVersions"
            ):
                return {
                    "data": [
                        {
                            "id": "version-1",
                            "attributes": {
                                "versionString": "1.7.1",
                                "appStoreState": "PREPARE_FOR_SUBMISSION",
                            },
                        }
                    ]
                }

            if (
                url
                == "https://api.appstoreconnect.apple.com/v1/appStoreVersions/version-1/appStoreVersionLocalizations"
            ):
                return {
                    "data": [
                        {"id": localization_id, "attributes": {"locale": locale}}
                        for locale, localization_id in version_localization_ids.items()
                    ]
                }

            if (
                url
                == f"https://api.appstoreconnect.apple.com/v1/apps/{uploader.APP_ID}/appInfos"
            ):
                return {"data": [{"id": "app-info-1"}]}

            if (
                url
                == "https://api.appstoreconnect.apple.com/v1/appInfos/app-info-1/appInfoLocalizations"
            ):
                return {
                    "data": [
                        {"id": localization_id, "attributes": {"locale": locale}}
                        for locale, localization_id in app_info_localization_ids.items()
                    ]
                }

            if method == "PATCH" and url.startswith(
                "https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/"
            ):
                return {"data": {}}

            if method == "PATCH" and url.startswith(
                "https://api.appstoreconnect.apple.com/v1/appInfoLocalizations/"
            ):
                return {"data": {}}

            self.fail(f"Unexpected App Store Connect request: {method} {url}")

        with patch.object(
            uploader, "parse_metadata", return_value=locales_metadata
        ), patch.object(uploader, "api_request", side_effect=fake_api_request):
            uploader.sync_app_store_metadata("1.7.1")

        app_info_updates = {
            call["url"]
            .rsplit("/", 1)[-1]
            .removeprefix("app-info-localization-"): call["body"]
            for call in calls
            if call["method"] == "PATCH"
            and call["url"].startswith(
                "https://api.appstoreconnect.apple.com/v1/appInfoLocalizations/"
            )
        }

        self.assertEqual(set(app_info_updates), set(self.subtitles))
        for locale, subtitle in self.subtitles.items():
            payload = app_info_updates[locale]
            self.assertEqual(payload["data"]["type"], "appInfoLocalizations")
            self.assertEqual(payload["data"]["attributes"]["subtitle"], subtitle)

        self.assertEqual(
            app_info_updates["es-ES"]["data"]["attributes"]["subtitle"],
            "Privacidad facial automática",
        )

        version_updates = [
            call["body"]
            for call in calls
            if call["method"] == "PATCH"
            and call["url"].startswith(
                "https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/"
            )
        ]
        self.assertTrue(version_updates)
        for payload in version_updates:
            self.assertNotIn("subtitle", payload["data"]["attributes"])

    def test_missing_app_info_localizations_create_subtitle_payloads(self):
        calls = []

        def fake_api_request(url, method="GET", body=None):
            calls.append({"url": url, "method": method, "body": body})

            if (
                url
                == f"https://api.appstoreconnect.apple.com/v1/apps/{uploader.APP_ID}/appInfos"
            ):
                return {"data": [{"id": "app-info-1"}]}

            if (
                url
                == "https://api.appstoreconnect.apple.com/v1/appInfos/app-info-1/appInfoLocalizations"
            ):
                return {"data": []}

            if (
                url == "https://api.appstoreconnect.apple.com/v1/appInfoLocalizations"
                and method == "POST"
            ):
                return {"data": {}}

            self.fail(f"Unexpected App Store Connect request: {method} {url}")

        locales_metadata = {
            locale: {"subtitle": subtitle}
            for locale, subtitle in self.subtitles.items()
        }
        with patch.object(uploader, "api_request", side_effect=fake_api_request):
            uploader.sync_app_info_localizations(locales_metadata)

        creates = {
            call["body"]["data"]["attributes"]["locale"]: call["body"]
            for call in calls
            if call["method"] == "POST"
            and call["url"]
            == "https://api.appstoreconnect.apple.com/v1/appInfoLocalizations"
        }

        self.assertEqual(set(creates), set(self.subtitles))
        for locale, subtitle in self.subtitles.items():
            payload = creates[locale]["data"]
            self.assertEqual(payload["type"], "appInfoLocalizations")
            self.assertEqual(payload["attributes"]["subtitle"], subtitle)
            self.assertEqual(payload["attributes"]["name"], uploader.APP_NAME)
            self.assertEqual(
                payload["relationships"]["appInfo"]["data"],
                {
                    "type": "appInfos",
                    "id": "app-info-1",
                },
            )


if __name__ == "__main__":
    unittest.main()
