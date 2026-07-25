#!/usr/bin/env python3
"""
Sync App Store Metadata from AppStoreSubmission/metadata.md into structured per-locale JSON configurations.
"""

import os
import re
import json

METADATA_MD_PATH = os.path.join(os.path.dirname(__file__), "..", "AppStoreSubmission", "metadata.md")
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "build", "metadata_dist")

def parse_metadata():
    if not os.path.exists(METADATA_MD_PATH):
        print(f"Error: {METADATA_MD_PATH} not found.")
        return

    with open(METADATA_MD_PATH, "r", encoding="utf-8") as f:
        content = f.read()

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Split sections by locale headers (e.g. ## 2. Localization: English (en-US))
    sections = re.split(r"## \d+\. Localization: ", content)

    locales = {
        "English (en-US)": "en-US",
        "Korean (ko)": "ko",
        "Japanese (ja)": "ja",
        "Spanish (es)": "es",
        "Simplified Chinese (zh-Hans)": "zh-Hans"
    }

    parsed_count = 0

    for section in sections[1:]:
        header_line = section.split("\n")[0].strip()
        locale_key = None
        for name, code in locales.items():
            if name in header_line:
                locale_key = code
                break

        if not locale_key:
            continue

        subtitle = extract_field(section, "Subtitle")
        promo_text = extract_field(section, "Promotional Text")
        keywords = extract_field(section, "Keywords")
        whats_new = extract_field(section, "What's New in Version 1.4")
        description = extract_field(section, "Description")

        data = {
            "locale": locale_key,
            "subtitle": subtitle,
            "promotionalText": promo_text,
            "keywords": keywords,
            "whatsNew": whats_new,
            "description": description
        }

        out_path = os.path.join(OUTPUT_DIR, f"{locale_key}.json")
        with open(out_path, "w", encoding="utf-8") as out_f:
            json.dump(data, out_f, ensure_ascii=False, indent=2)

        print(f"✅ Generated {locale_key}.json -> {out_path}")
        parsed_count += 1

    print(f"🎉 Generated {parsed_count} metadata configurations in {OUTPUT_DIR}")

def extract_field(section, field_name):
    pattern = rf"### {re.escape(field_name)}\n(.*?)(?=\n### |\n---|\Z)"
    match = re.search(pattern, section, re.DOTALL)
    if match:
        return match.group(1).strip()
    return ""

if __name__ == "__main__":
    parse_metadata()
