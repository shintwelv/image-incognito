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
PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
KEY_PATH = os.path.join(PROJECT_DIR, ".keys", "AuthKey_XFW954Z6SB.p8")
ENV_PATH = os.path.join(PROJECT_DIR, ".keys", "appstore_connect.env")
METADATA_MD_PATH = os.path.join(PROJECT_DIR, "AppStoreSubmission", "metadata.md")

# Default metadata URLs
SUPPORT_URL = "https://shintwl.notion.site/Incognify-Support-334319f036d080b9a436dae4e4d99884?source=copy_link"
MARKETING_URL = "https://shinil.github.io/image-incognito"

LOCALE_MAP = {
    "en-US": "en-US",
    "ko": "ko",
    "ja": "ja",
    "es": "es-ES",
    "zh-Hans": "zh-Hans"
}

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

def sync_app_store_metadata(version_string="1.5"):
    print(f"🔄 Authenticating with App Store Connect API...")
    locales_meta = parse_metadata()

    # 1. Fetch versions for app
    versions_data = api_request(f"https://api.appstoreconnect.apple.com/v1/apps/{APP_ID}/appStoreVersions")
    version_id = None

    for ver in versions_data.get("data", []):
        v_str = ver["attributes"]["versionString"]
        v_state = ver["attributes"]["appStoreState"]
        if v_str == version_string and v_state not in ["READY_FOR_SALE", "DEVELOPER_REMOVED_FROM_SALE"]:
            version_id = ver["id"]
            print(f"ℹ️ Found editable App Store Version {version_string} (ID: {version_id}, State: {v_state})")
            break
        elif v_str == version_string:
            print(f"ℹ️ Found existing version {version_string} in state '{v_state}' (non-editable). Will create new editable version...")

    # 2. Create version if it does not exist or previous is not editable
    if not version_id:
        print(f"✨ Version {version_string} not editable or not found. Creating new App Store Version {version_string}...")
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
        version_id = res["data"]["id"]
        print(f"✅ Created Version {version_string} (ID: {version_id})")

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

    print(f"\n🎉 All 5 localizations successfully updated on App Store Connect for Version {version_string}!")

if __name__ == "__main__":
    sync_app_store_metadata("1.7.1")
