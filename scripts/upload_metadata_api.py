#!/usr/bin/env python3
"""
Automatic App Store Connect Metadata Uploader
Reads parsed metadata from AppStoreSubmission/metadata.md and directly creates/updates
the requested App Store version and all 5 localizations via App Store Connect REST API.
"""

import os
import re
import json
import time
import base64
import subprocess
import tempfile
import urllib.request
import urllib.error

APP_ID = "6761360065"
APP_NAME = "Incognify"
PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEY_PATH = os.path.join(PROJECT_DIR, ".keys", "AuthKey_XFW954Z6SB.p8")
ENV_PATH = os.path.join(PROJECT_DIR, ".keys", "appstore_connect.env")
METADATA_MD_PATH = os.path.join(PROJECT_DIR, "AppStoreSubmission", "metadata.md")

# Default metadata URLs
SUPPORT_URL = "https://shintwl.notion.site/Incognify-Support-334319f036d080b9a436dae4e4d99884?source=copy_link"
MARKETING_URL = "https://shintwelv.github.io/image-incognito/"

LOCALE_MAP = {
    "en-US": "en-US",
    "ko": "ko",
    "ja": "ja",
    "es": "es-ES",
    "zh-Hans": "zh-Hans"
}

DRAFT_APP_STORE_STATE = "PREPARE_FOR_SUBMISSION"

def load_credentials():
    key_id = "XFW954Z6SB"
    issuer_id = "dcc1c94a-71ee-402f-b14f-031f47dee9ed"
    if os.path.exists(ENV_PATH):
        with open(ENV_PATH, "r") as f:
            for line in f:
                if "=" in line:
                    k, v = line.strip().split("=", 1)
                    v = v.strip('"')
                    if k == "APPSTORE_KEY_ID": key_id = v
                    elif k == "APPSTORE_ISSUER_ID": issuer_id = v
    return key_id, issuer_id

def base64url_encode(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("utf-8")

def der_to_raw_sig(der):
    idx = 2
    r_len = der[idx + 1]
    r = der[idx + 2 : idx + 2 + r_len]
    idx = idx + 2 + r_len
    s_len = der[idx + 1]
    s = der[idx + 2 : idx + 2 + s_len]
    r = r[-32:].rjust(32, b"\x00")
    s = s[-32:].rjust(32, b"\x00")
    return r + s

def generate_jwt():
    key_id, issuer_id = load_credentials()
    header = {"alg": "ES256", "kid": key_id, "typ": "JWT"}
    now = int(time.time())
    payload = {
        "iss": issuer_id,
        "iat": now,
        "exp": now + 1200,
        "aud": "appstoreconnect-v1"
    }

    header_b64 = base64url_encode(json.dumps(header).encode("utf-8"))
    payload_b64 = base64url_encode(json.dumps(payload).encode("utf-8"))
    signing_input = f"{header_b64}.{payload_b64}"

    with tempfile.NamedTemporaryFile("w+", delete=False) as f:
        f.write(signing_input)
        f.flush()
        res = subprocess.run(["openssl", "dgst", "-sha256", "-sign", KEY_PATH, f.name], capture_output=True)

    if res.returncode != 0:
        raise Exception(f"OpenSSL signing failed: {res.stderr.decode('utf-8')}")

    raw_sig = der_to_raw_sig(res.stdout)
    return f"{signing_input}.{base64url_encode(raw_sig)}"

def api_request(url, method="GET", body=None):
    token = generate_jwt()
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    data = json.dumps(body).encode("utf-8") if body else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8")
        print(f"❌ API Error {e.code} ({url}): {err_body}")
        raise e

def parse_metadata():
    with open(METADATA_MD_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    sections = re.split(r"## \d+\. Localization: ", content)
    locales_data = {}

    local_mapping = {
        "English (en-US)": "en-US",
        "Korean (ko)": "ko",
        "Japanese (ja)": "ja",
        "Spanish (es)": "es-ES",
        "Simplified Chinese (zh-Hans)": "zh-Hans"
    }

    for section in sections[1:]:
        header_line = section.split("\n")[0].strip()
        code = None
        for name, target_code in local_mapping.items():
            if name in header_line:
                code = target_code
                break

        if not code: continue

        subtitle = extract_field(section, "Subtitle")
        promo = extract_field(section, "Promotional Text")
        keywords = extract_field(section, "Keywords")
        whats_new = extract_whats_new(section)
        description = extract_field(section, "Description")

        locales_data[code] = {
            "subtitle": subtitle,
            "promotionalText": promo,
            "keywords": keywords,
            "whatsNew": whats_new,
            "description": description,
            "supportUrl": SUPPORT_URL,
            "marketingUrl": MARKETING_URL
        }

    return locales_data

def extract_whats_new(section):
    pattern = r"### What's New.*?\n(.*?)(?=\n### |\n---|\Z)"
    match = re.search(pattern, section, re.DOTALL)
    if match:
        return match.group(1).strip()
    return ""

def extract_field(section, field_name):
    pattern = rf"### {re.escape(field_name)}\n(.*?)(?=\n### |\n---|\Z)"
    match = re.search(pattern, section, re.DOTALL)
    if match:
        return match.group(1).strip()
    return ""

def truncate_keywords(keywords_str, max_len=100):
    if len(keywords_str) <= max_len:
        return keywords_str
    parts = [p.strip() for p in keywords_str.split(",")]
    result = []
    current_len = 0
    for p in parts:
        added_len = len(p) + (2 if result else 0)
        if current_len + added_len <= max_len:
            result.append(p)
            current_len += added_len
        else:
            break
    return ", ".join(result)

def state_values(resource):
    if not isinstance(resource, dict):
        return []
    attributes = resource.get("attributes", {})
    if not isinstance(attributes, dict):
        return []
    return [
        attributes[field]
        for field in ("appStoreState", "state")
        if attributes.get(field) is not None
    ]


def is_draft_resource(resource):
    states = state_values(resource)
    return bool(states) and all(state == DRAFT_APP_STORE_STATE for state in states)


def require_draft_resource(resource, resource_label):
    if not isinstance(resource, dict) or not resource.get("id"):
        raise RuntimeError(f"{resource_label} selected for metadata sync must include an id")

    states = state_values(resource)
    if not states or any(state != DRAFT_APP_STORE_STATE for state in states):
        observed = ", ".join(str(state) for state in states) or "no state"
        raise RuntimeError(
            f"{resource_label} must be in {DRAFT_APP_STORE_STATE} with no conflicting state values; "
            f"found {observed}"
        )
    return resource["id"]


def require_draft_version(version, version_string):
    version_id = require_draft_resource(version, f"App Store Version {version_string}")
    attributes = version.get("attributes", {})
    if attributes.get("versionString") != version_string:
        raise RuntimeError(
            f"App Store Version selected for {version_string} must report the same versionString"
        )
    return version_id


def fetch_all_pages(first_url, collection_label):
    """Fetch a collection completely before making a uniqueness decision."""
    data = []
    next_url = first_url
    visited_urls = set()

    while next_url is not None:
        if not isinstance(next_url, str) or not next_url:
            raise RuntimeError(f"{collection_label} pagination returned an invalid next link")
        if next_url in visited_urls:
            raise RuntimeError(f"{collection_label} pagination returned a repeated next link")
        visited_urls.add(next_url)

        page = api_request(next_url)
        page_data = page.get("data") if isinstance(page, dict) else None
        if not isinstance(page_data, list):
            raise RuntimeError(f"{collection_label} pagination response must contain a data list")
        data.extend(page_data)

        links = page.get("links", {})
        if links is None:
            next_url = None
        elif not isinstance(links, dict):
            raise RuntimeError(f"{collection_label} pagination response must contain a links object")
        else:
            next_url = links.get("next")

    return data


def select_unique_draft_app_info(app_infos):
    """Return the one App Info resource that belongs to the editable draft.

    App Store Connect exposes App Info separately from App Store Versions, so
    there is no direct version-id relationship to follow. The draft lifecycle
    state is the public seam available here; requiring exactly one candidate
    prevents a metadata sync from falling back to the live product page.
    """
    candidates = [
        app_info
        for app_info in app_infos
        if is_draft_resource(app_info)
    ]
    if len(candidates) != 1:
        raise RuntimeError(
            "Expected exactly one App Info in "
            f"{DRAFT_APP_STORE_STATE} for metadata sync; found {len(candidates)}"
        )
    app_info = candidates[0]
    require_draft_resource(app_info, f"The {DRAFT_APP_STORE_STATE} App Info")
    return app_info


def sync_app_info_localizations(locales_meta, target_version, version_string):
    require_draft_version(target_version, version_string)

    app_infos = fetch_all_pages(
        f"https://api.appstoreconnect.apple.com/v1/apps/{APP_ID}/appInfos", "App Info"
    )
    app_info = select_unique_draft_app_info(app_infos)

    app_info_id = app_info["id"]
    app_info_locs_res = api_request(
        f"https://api.appstoreconnect.apple.com/v1/appInfos/{app_info_id}/appInfoLocalizations"
    )
    existing_locs = {
        item["attributes"]["locale"]: item["id"]
        for item in app_info_locs_res.get("data", [])
    }

    for locale_code, meta in locales_meta.items():
        attributes = {"subtitle": meta["subtitle"]}

        if locale_code in existing_locs:
            localization_id = existing_locs[locale_code]
            print(f"📝 Updating [{locale_code}] App Info subtitle (ID: {localization_id})...")
            api_request(
                f"https://api.appstoreconnect.apple.com/v1/appInfoLocalizations/{localization_id}",
                method="PATCH",
                body={
                    "data": {
                        "type": "appInfoLocalizations",
                        "id": localization_id,
                        "attributes": attributes,
                    }
                },
            )
        else:
            print(f"➕ Creating [{locale_code}] App Info localization...")
            api_request(
                "https://api.appstoreconnect.apple.com/v1/appInfoLocalizations",
                method="POST",
                body={
                    "data": {
                        "type": "appInfoLocalizations",
                        "attributes": {
                            "locale": locale_code,
                            "name": APP_NAME,
                            **attributes,
                        },
                        "relationships": {
                            "appInfo": {
                                "data": {
                                    "type": "appInfos",
                                    "id": app_info_id,
                                }
                            }
                        },
                    }
                },
            )

def sync_app_store_metadata(version_string="1.5"):
    print(f"🔄 Authenticating with App Store Connect API...")
    locales_meta = parse_metadata()

    # 1. Fetch versions for app
    versions_data = fetch_all_pages(
        f"https://api.appstoreconnect.apple.com/v1/apps/{APP_ID}/appStoreVersions",
        "App Store Version",
    )
    matching_versions = [
        version
        for version in versions_data
        if version.get("attributes", {}).get("versionString") == version_string
    ]
    if len(matching_versions) > 1:
        raise RuntimeError(
            f"Expected at most one App Store Version {version_string}; found {len(matching_versions)}"
        )

    version_id = None
    target_version = None
    if matching_versions:
        target_version = matching_versions[0]
        version_id = require_draft_version(target_version, version_string)
        print(
            f"ℹ️ Found editable App Store Version {version_string} "
            f"(ID: {version_id}, State: {DRAFT_APP_STORE_STATE})"
        )

    # 2. Create a version only when the requested version does not exist.
    if not version_id:
        print(f"✨ Version {version_string} not found. Creating new App Store Version {version_string}...")
        create_payload = {
            "data": {
                "type": "appStoreVersions",
                "attributes": {
                    "platform": "IOS",
                    "versionString": version_string
                },
                "relationships": {
                    "app": {
                        "data": {
                            "type": "apps",
                            "id": APP_ID
                        }
                    }
                }
            }
        }
        res = api_request("https://api.appstoreconnect.apple.com/v1/appStoreVersions", method="POST", body=create_payload)
        target_version = res.get("data") if isinstance(res, dict) else None
        version_id = require_draft_version(target_version, version_string)
        print(f"✅ Created Version {version_string} (ID: {version_id})")

    # App Info has no direct App Store Version relationship in the API. Match
    # the intended draft through its lifecycle state and fail closed otherwise.
    sync_app_info_localizations(locales_meta, target_version, version_string)

    # 3. Fetch existing localizations for this version
    locs_res = api_request(f"https://api.appstoreconnect.apple.com/v1/appStoreVersions/{version_id}/appStoreVersionLocalizations")
    existing_locs = {item["attributes"]["locale"]: item["id"] for item in locs_res.get("data", [])}

    # 4. Update or create each version localization
    for locale_code, meta in locales_meta.items():
        attr_payload = {
            "description": meta["description"],
            "keywords": truncate_keywords(meta["keywords"]),
            "whatsNew": meta["whatsNew"],
            "promotionalText": meta["promotionalText"],
            "supportUrl": meta["supportUrl"],
            "marketingUrl": meta["marketingUrl"]
        }

        if locale_code in existing_locs:
            loc_id = existing_locs[locale_code]
            print(f"📝 Updating [{locale_code}] version localization (ID: {loc_id})...")
            patch_payload = {
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "id": loc_id,
                    "attributes": attr_payload
                }
            }
            api_request(f"https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations/{loc_id}", method="PATCH", body=patch_payload)
            print(f"✅ [{locale_code}] version metadata updated!")
        else:
            print(f"➕ Creating [{locale_code}] version localization...")
            post_payload = {
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "attributes": {
                        "locale": locale_code,
                        **attr_payload
                    },
                    "relationships": {
                        "appStoreVersion": {
                            "data": {
                                "type": "appStoreVersions",
                                "id": version_id
                            }
                        }
                    }
                }
            }
            api_request("https://api.appstoreconnect.apple.com/v1/appStoreVersionLocalizations", method="POST", body=post_payload)
            print(f"✅ [{locale_code}] version localization created!")

    print(f"\n🎉 All 5 App Info and version localizations successfully updated on App Store Connect for Version {version_string}!")

if __name__ == "__main__":
    sync_app_store_metadata("1.8.0")
