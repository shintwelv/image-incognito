import io
import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock, mock_open, patch

SCRIPTS_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPTS_DIR))

import upload_metadata_api as uploader


def draft_version(version_string="1.7.1", version_id="draft-version"):
    return {
        "id": version_id,
        "attributes": {
            "versionString": version_string,
            "appStoreState": "PREPARE_FOR_SUBMISSION",
        },
    }


class AppInfoLocalizationSubtitlePayloadTests(unittest.TestCase):
    subtitles = {
        "en-US": "Auto Face Privacy for Photos",
        "ko": "자동 얼굴 프라이버시 보호",
        "ja": "写真の自動顔プライバシー保護",
        "es-ES": "Privacidad facial automática",
        "zh-Hans": "照片人脸自动隐私保护",
    }

    def test_sync_uses_draft_app_info_when_live_app_info_is_returned_first(self):
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
                return {
                    "data": [
                        {
                            "id": "live-app-info",
                            "attributes": {"appStoreState": "READY_FOR_SALE"},
                        },
                        {
                            "id": "draft-app-info",
                            "attributes": {"appStoreState": "PREPARE_FOR_SUBMISSION"},
                        },
                    ]
                }

            if (
                url
                == "https://api.appstoreconnect.apple.com/v1/appInfos/draft-app-info/appInfoLocalizations"
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
        self.assertFalse(
            any("live-app-info" in call["url"] for call in calls),
            "The live App Info must never be selected for a draft metadata sync.",
        )
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
                return {
                    "data": [
                        {
                            "id": "app-info-1",
                            "attributes": {"appStoreState": "PREPARE_FOR_SUBMISSION"},
                        }
                    ]
                }

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
            uploader.sync_app_info_localizations(locales_metadata, draft_version(), "1.7.1")

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

    def test_sync_fails_closed_when_no_draft_app_info_exists(self):
        calls = []

        def fake_api_request(url, method="GET", body=None):
            calls.append({"url": url, "method": method, "body": body})
            if url == f"https://api.appstoreconnect.apple.com/v1/apps/{uploader.APP_ID}/appInfos":
                return {
                    "data": [
                        {
                            "id": "live-app-info",
                            "attributes": {"appStoreState": "READY_FOR_SALE"},
                        }
                    ]
                }
            self.fail(f"Unexpected App Store Connect request: {method} {url}")

        with patch.object(uploader, "api_request", side_effect=fake_api_request):
            with self.assertRaisesRegex(RuntimeError, "exactly one.*PREPARE_FOR_SUBMISSION"):
                uploader.sync_app_info_localizations(
                    {"en-US": {"subtitle": "Draft only"}}, draft_version(), "1.7.1"
                )

        self.assertEqual(len(calls), 1)

    def test_sync_fails_closed_when_draft_app_info_is_ambiguous(self):
        calls = []

        def fake_api_request(url, method="GET", body=None):
            calls.append({"url": url, "method": method, "body": body})
            if url == f"https://api.appstoreconnect.apple.com/v1/apps/{uploader.APP_ID}/appInfos":
                return {
                    "data": [
                        {
                            "id": "draft-app-info-a",
                            "attributes": {"appStoreState": "PREPARE_FOR_SUBMISSION"},
                        },
                        {
                            "id": "draft-app-info-b",
                            "attributes": {"state": "PREPARE_FOR_SUBMISSION"},
                        },
                    ]
                }
            self.fail(f"Unexpected App Store Connect request: {method} {url}")

        with patch.object(uploader, "api_request", side_effect=fake_api_request):
            with self.assertRaisesRegex(RuntimeError, "exactly one.*PREPARE_FOR_SUBMISSION"):
                uploader.sync_app_info_localizations(
                    {"en-US": {"subtitle": "Draft only"}}, draft_version(), "1.7.1"
                )

        self.assertEqual(len(calls), 1)

    def test_sync_fails_closed_when_app_info_state_aliases_conflict(self):
        calls = []

        def fake_api_request(url, method="GET", body=None):
            calls.append({"url": url, "method": method, "body": body})
            if url == f"https://api.appstoreconnect.apple.com/v1/apps/{uploader.APP_ID}/appInfos":
                return {
                    "data": [
                        {
                            "id": "conflicting-app-info",
                            "attributes": {
                                "appStoreState": "PREPARE_FOR_SUBMISSION",
                                "state": "READY_FOR_SALE",
                            },
                        }
                    ]
                }
            self.fail(f"Unexpected App Store Connect request: {method} {url}")

        with patch.object(uploader, "api_request", side_effect=fake_api_request):
            with self.assertRaisesRegex(RuntimeError, "exactly one.*PREPARE_FOR_SUBMISSION"):
                uploader.sync_app_info_localizations(
                    {"en-US": {"subtitle": "Draft only"}}, draft_version(), "1.7.1"
                )

        self.assertEqual(len(calls), 1)

    def test_sync_fails_closed_when_draft_app_info_has_no_id(self):
        calls = []

        def fake_api_request(url, method="GET", body=None):
            calls.append({"url": url, "method": method, "body": body})
            if url == f"https://api.appstoreconnect.apple.com/v1/apps/{uploader.APP_ID}/appInfos":
                return {
                    "data": [
                        {
                            "attributes": {"state": "PREPARE_FOR_SUBMISSION"},
                        }
                    ]
                }
            self.fail(f"Unexpected App Store Connect request: {method} {url}")

        with patch.object(uploader, "api_request", side_effect=fake_api_request):
            with self.assertRaisesRegex(RuntimeError, "must include an id"):
                uploader.sync_app_info_localizations(
                    {"en-US": {"subtitle": "Draft only"}}, draft_version(), "1.7.1"
                )

        self.assertEqual(len(calls), 1)

    def test_sync_fails_closed_before_app_info_writes_when_target_version_is_not_a_draft(self):
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
                                "appStoreState": "WAITING_FOR_REVIEW",
                            },
                        }
                    ]
                }
            self.fail(f"Unexpected App Store Connect request: {method} {url}")

        with patch.object(
            uploader, "parse_metadata", return_value={"en-US": {"subtitle": "Draft only"}}
        ), patch.object(uploader, "api_request", side_effect=fake_api_request):
            with self.assertRaisesRegex(RuntimeError, "1.7.1.*PREPARE_FOR_SUBMISSION"):
                uploader.sync_app_store_metadata("1.7.1")

        self.assertEqual(len(calls), 1)

    def test_sync_fails_closed_when_target_version_state_aliases_conflict(self):
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
                                "state": "READY_FOR_SALE",
                            },
                        }
                    ]
                }
            self.fail(f"Unexpected App Store Connect request: {method} {url}")

        with patch.object(
            uploader, "parse_metadata", return_value={"en-US": {"subtitle": "Draft only"}}
        ), patch.object(uploader, "api_request", side_effect=fake_api_request):
            with self.assertRaisesRegex(RuntimeError, "no conflicting state values"):
                uploader.sync_app_store_metadata("1.7.1")

        self.assertEqual(len(calls), 1)

    def test_sync_fails_closed_when_existing_target_version_has_no_id(self):
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
                            "id": "",
                            "attributes": {
                                "versionString": "1.7.1",
                                "appStoreState": "PREPARE_FOR_SUBMISSION",
                            },
                        }
                    ]
                }
            self.fail(f"Unexpected App Store Connect request: {method} {url}")

        with patch.object(
            uploader, "parse_metadata", return_value={"en-US": {"subtitle": "Draft only"}}
        ), patch.object(uploader, "api_request", side_effect=fake_api_request):
            with self.assertRaisesRegex(RuntimeError, "must include an id"):
                uploader.sync_app_store_metadata("1.7.1")

        self.assertEqual(len(calls), 1)

    def test_sync_fails_closed_when_matching_versions_span_pages(self):
        calls = []
        versions_url = f"https://api.appstoreconnect.apple.com/v1/apps/{uploader.APP_ID}/appStoreVersions"
        next_url = f"{versions_url}?cursor=next"

        def fake_api_request(url, method="GET", body=None):
            calls.append({"url": url, "method": method, "body": body})
            if url == versions_url:
                return {"data": [draft_version(version_id="version-1")], "links": {"next": next_url}}
            if url == next_url:
                return {"data": [draft_version(version_id="version-2")], "links": {}}
            self.fail(f"Unexpected App Store Connect request: {method} {url}")

        with patch.object(
            uploader, "parse_metadata", return_value={"en-US": {"subtitle": "Draft only"}}
        ), patch.object(uploader, "api_request", side_effect=fake_api_request):
            with self.assertRaisesRegex(RuntimeError, "at most one App Store Version 1.7.1; found 2"):
                uploader.sync_app_store_metadata("1.7.1")

        self.assertEqual([call["url"] for call in calls], [versions_url, next_url])

    def test_sync_fails_closed_when_draft_app_infos_span_pages(self):
        calls = []
        app_infos_url = f"https://api.appstoreconnect.apple.com/v1/apps/{uploader.APP_ID}/appInfos"
        next_url = f"{app_infos_url}?cursor=next"

        def fake_api_request(url, method="GET", body=None):
            calls.append({"url": url, "method": method, "body": body})
            if url == app_infos_url:
                return {
                    "data": [
                        {
                            "id": "draft-app-info-a",
                            "attributes": {"appStoreState": "PREPARE_FOR_SUBMISSION"},
                        }
                    ],
                    "links": {"next": next_url},
                }
            if url == next_url:
                return {
                    "data": [
                        {
                            "id": "draft-app-info-b",
                            "attributes": {"appStoreState": "PREPARE_FOR_SUBMISSION"},
                        }
                    ],
                    "links": {},
                }
            self.fail(f"Unexpected App Store Connect request: {method} {url}")

        with patch.object(uploader, "api_request", side_effect=fake_api_request):
            with self.assertRaisesRegex(RuntimeError, "exactly one.*PREPARE_FOR_SUBMISSION"):
                uploader.sync_app_info_localizations(
                    {"en-US": {"subtitle": "Draft only"}}, draft_version(), "1.7.1"
                )

        self.assertEqual([call["url"] for call in calls], [app_infos_url, next_url])

    def test_sync_fails_closed_when_created_version_cannot_be_verified(self):
        versions_url = f"https://api.appstoreconnect.apple.com/v1/apps/{uploader.APP_ID}/appStoreVersions"
        create_url = "https://api.appstoreconnect.apple.com/v1/appStoreVersions"
        invalid_responses = {
            "missing-id": (
                {
                    "attributes": {
                        "versionString": "2.0",
                        "appStoreState": "PREPARE_FOR_SUBMISSION",
                    }
                },
                "must include an id",
            ),
            "missing-state": (
                {"id": "created-version", "attributes": {"versionString": "2.0"}},
                "PREPARE_FOR_SUBMISSION",
            ),
            "wrong-state": (
                {
                    "id": "created-version",
                    "attributes": {
                        "versionString": "2.0",
                        "appStoreState": "READY_FOR_SALE",
                    },
                },
                "PREPARE_FOR_SUBMISSION",
            ),
            "wrong-version": (
                {
                    "id": "created-version",
                    "attributes": {
                        "versionString": "2.1",
                        "appStoreState": "PREPARE_FOR_SUBMISSION",
                    },
                },
                "same versionString",
            ),
        }

        for label, (created_version, error_text) in invalid_responses.items():
            with self.subTest(label=label):
                calls = []

                def fake_api_request(url, method="GET", body=None):
                    calls.append({"url": url, "method": method, "body": body})
                    if url == versions_url:
                        return {"data": []}
                    if url == create_url and method == "POST":
                        return {"data": created_version}
                    self.fail(f"Unexpected App Store Connect request: {method} {url}")

                with patch.object(
                    uploader, "parse_metadata", return_value={"en-US": {"subtitle": "Draft only"}}
                ), patch.object(uploader, "api_request", side_effect=fake_api_request):
                    with self.assertRaisesRegex(RuntimeError, error_text):
                        uploader.sync_app_store_metadata("2.0")

                self.assertEqual([call["url"] for call in calls], [versions_url, create_url])

    def test_app_info_sync_requires_a_validated_target_version(self):
        with patch.object(uploader, "api_request") as api_request:
            with self.assertRaisesRegex(RuntimeError, "no conflicting state values"):
                uploader.sync_app_info_localizations(
                    {"en-US": {"subtitle": "Draft only"}},
                    {
                        "id": "version-1",
                        "attributes": {
                            "versionString": "1.7.1",
                            "appStoreState": "PREPARE_FOR_SUBMISSION",
                            "state": "READY_FOR_SALE",
                        },
                    },
                    "1.7.1",
                )

        api_request.assert_not_called()


class MetadataUploaderUtilityTests(unittest.TestCase):
    def test_parse_metadata_reads_all_release_locales(self):
        metadata = uploader.parse_metadata()

        self.assertEqual(set(metadata), {"en-US", "ko", "ja", "es-ES", "zh-Hans"})
        self.assertEqual(metadata["ko"]["subtitle"], "자동 얼굴 프라이버시 보호")
        self.assertEqual(metadata["es-ES"]["subtitle"], "Privacidad facial automática")
        self.assertEqual(metadata["en-US"]["supportUrl"], uploader.SUPPORT_URL)
        self.assertEqual(metadata["zh-Hans"]["marketingUrl"], uploader.MARKETING_URL)

    def test_extract_helpers_and_keyword_truncation_cover_present_and_absent_values(self):
        section = """### Subtitle
Draft subtitle

### What's New in Version 1.7.1
- A first change
- A second change

### Description
Draft description
"""

        self.assertEqual(uploader.extract_field(section, "Subtitle"), "Draft subtitle")
        self.assertEqual(uploader.extract_field(section, "Missing"), "")
        self.assertEqual(
            uploader.extract_whats_new(section), "- A first change\n- A second change"
        )
        self.assertEqual(uploader.extract_whats_new("### Description\nOnly description"), "")
        self.assertEqual(uploader.truncate_keywords("short, keywords"), "short, keywords")
        self.assertEqual(
            uploader.truncate_keywords("alpha, beta, charlie", max_len=12), "alpha, beta"
        )

    def test_load_credentials_uses_defaults_and_local_overrides(self):
        with patch.object(uploader.os.path, "exists", return_value=False):
            default_key_id, default_issuer_id = uploader.load_credentials()
            self.assertTrue(default_key_id)
            self.assertTrue(default_issuer_id)

        env = 'APPSTORE_KEY_ID="test-key"\nAPPSTORE_ISSUER_ID="test-issuer"\nIGNORED=value\n'
        with patch.object(uploader.os.path, "exists", return_value=True), patch(
            "builtins.open", mock_open(read_data=env)
        ):
            self.assertEqual(uploader.load_credentials(), ("test-key", "test-issuer"))

    def test_signing_helpers_generate_expected_base64url_jwt(self):
        der_signature = b"\x30\x06\x02\x01\x01\x02\x01\x02"
        raw_signature = uploader.der_to_raw_sig(der_signature)
        self.assertEqual(len(raw_signature), 64)
        self.assertEqual(raw_signature[-1], 2)
        self.assertEqual(uploader.base64url_encode(b"a?"), "YT8")

        temp_file = MagicMock()
        temp_file.name = "/tmp/metadata-signing-input"
        temp_context = MagicMock()
        temp_context.__enter__.return_value = temp_file
        temp_context.__exit__.return_value = False
        completed = SimpleNamespace(returncode=0, stdout=der_signature, stderr=b"")
        with patch.object(
            uploader, "load_credentials", return_value=("test-key", "test-issuer")
        ), patch.object(uploader.time, "time", return_value=1000), patch.object(
            uploader.tempfile, "NamedTemporaryFile", return_value=temp_context
        ), patch.object(uploader.subprocess, "run", return_value=completed) as run:
            token = uploader.generate_jwt()

        self.assertEqual(len(token.split(".")), 3)
        temp_file.write.assert_called_once()
        temp_file.flush.assert_called_once()
        self.assertEqual(run.call_args.args[0][:4], ["openssl", "dgst", "-sha256", "-sign"])

    def test_generate_jwt_surfaces_signing_failure(self):
        temp_file = MagicMock()
        temp_file.name = "/tmp/metadata-signing-input"
        temp_context = MagicMock()
        temp_context.__enter__.return_value = temp_file
        temp_context.__exit__.return_value = False
        failed = SimpleNamespace(returncode=1, stdout=b"", stderr=b"signing failed")
        with patch.object(
            uploader, "load_credentials", return_value=("test-key", "test-issuer")
        ), patch.object(
            uploader.tempfile, "NamedTemporaryFile", return_value=temp_context
        ), patch.object(uploader.subprocess, "run", return_value=failed):
            with self.assertRaisesRegex(Exception, "OpenSSL signing failed"):
                uploader.generate_jwt()

    def test_api_request_serializes_successful_requests_and_raises_http_errors(self):
        response = MagicMock()
        response.read.return_value = b'{"data":{"id":"result"}}'
        response.__enter__.return_value = response
        response.__exit__.return_value = False
        with patch.object(uploader, "generate_jwt", return_value="test-token"), patch.object(
            uploader.urllib.request, "urlopen", return_value=response
        ) as urlopen:
            result = uploader.api_request(
                "https://example.com/resource", method="PATCH", body={"value": "draft"}
            )

        self.assertEqual(result, {"data": {"id": "result"}})
        request = urlopen.call_args.args[0]
        self.assertEqual(request.get_method(), "PATCH")
        self.assertEqual(request.data, b'{"value": "draft"}')

        http_error = uploader.urllib.error.HTTPError(
            "https://example.com/resource", 400, "Bad Request", None, io.BytesIO(b'{"error":"bad"}')
        )
        with patch.object(uploader, "generate_jwt", return_value="test-token"), patch.object(
            uploader.urllib.request, "urlopen", side_effect=http_error
        ):
            with self.assertRaises(uploader.urllib.error.HTTPError):
                uploader.api_request("https://example.com/resource")
        http_error.close()

    def test_sync_creates_a_version_then_creates_missing_version_localization(self):
        calls = []
        locales_metadata = {
            "en-US": {
                "subtitle": "Draft subtitle",
                "description": "Draft description",
                "keywords": "draft, keywords",
                "whatsNew": "- Draft change",
                "promotionalText": "Draft promotion",
                "supportUrl": "https://example.com/support",
                "marketingUrl": "https://example.com/marketing",
            }
        }

        def fake_api_request(url, method="GET", body=None):
            calls.append({"url": url, "method": method, "body": body})
            if url == f"https://api.appstoreconnect.apple.com/v1/apps/{uploader.APP_ID}/appStoreVersions":
                return {"data": []}
            if url == "https://api.appstoreconnect.apple.com/v1/appStoreVersions" and method == "POST":
                return {
                    "data": {
                        "id": "created-version",
                        "attributes": {
                            "versionString": "2.0",
                            "appStoreState": "PREPARE_FOR_SUBMISSION",
                        },
                    }
                }
            if url == f"https://api.appstoreconnect.apple.com/v1/apps/{uploader.APP_ID}/appInfos":
                return {
                    "data": [
                        {
                            "id": "draft-app-info",
                            "attributes": {"appStoreState": "PREPARE_FOR_SUBMISSION"},
                        }
                    ]
                }
            if url == "https://api.appstoreconnect.apple.com/v1/appInfos/draft-app-info/appInfoLocalizations":
                return {"data": [{"id": "info-loc", "attributes": {"locale": "en-US"}}]}
            if url == "https://api.appstoreconnect.apple.com/v1/appInfoLocalizations/info-loc" and method == "PATCH":
                return {"data": {}}
            if url == "https://api.appstoreconnect.apple.com/v1/appStoreVersions/created-version/appStoreVersionLocalizations":
                return {"data": []}
            if url == "https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations" and method == "POST":
                return {"data": {}}
            self.fail(f"Unexpected App Store Connect request: {method} {url}")

        with patch.object(uploader, "parse_metadata", return_value=locales_metadata), patch.object(
            uploader, "api_request", side_effect=fake_api_request
        ):
            uploader.sync_app_store_metadata("2.0")

        version_create = next(call for call in calls if call["url"].endswith("/appStoreVersions") and call["method"] == "POST")
        self.assertEqual(version_create["body"]["data"]["attributes"]["versionString"], "2.0")
        localization_create = next(
            call
            for call in calls
            if call["url"].endswith("/appStoreVersionLocalizations") and call["method"] == "POST"
        )
        self.assertEqual(
            localization_create["body"]["data"]["relationships"]["appStoreVersion"]["data"]["id"],
            "created-version",
        )


if __name__ == "__main__":
    unittest.main()
