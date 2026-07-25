#!/bin/bash
# ==============================================================================
# Incognify One-Shot App Store Build, Validation, Upload & Metadata Sync
# ==============================================================================

set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/Incognify.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"
IPA_PATH="${EXPORT_PATH}/image-incognito.ipa"
EXPORT_OPTIONS="${BUILD_DIR}/ExportOptions.plist"

echo "================================================================="
echo "🚀 1/4: Syncing App Store Metadata across 5 localizations..."
echo "================================================================="
python3 "${PROJECT_DIR}/scripts/sync_metadata.py"

echo ""
echo "================================================================="
echo "📦 2/4: Archiving Xcode Release Build..."
echo "================================================================="
xcodebuild archive \
  -project "${PROJECT_DIR}/iOS/image-incognito/image-incognito.xcodeproj" \
  -scheme image-incognito \
  -archivePath "${ARCHIVE_PATH}" \
  -destination 'generic/platform=iOS' \
  -quiet

echo ""
echo "================================================================="
echo "📱 3/4: Exporting Signed IPA Package..."
echo "================================================================="
xcodebuild -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -exportOptionsPlist "${EXPORT_OPTIONS}" \
  -quiet

echo ""
echo "================================================================="
echo "✅ 4/4: One-Shot App Store Connect Validation & Upload Status"
echo "================================================================="
if [ -f "${IPA_PATH}" ]; then
  echo "SUCCESS: IPA Package Ready at -> ${IPA_PATH}"
  echo "Metadata JSON Configs Ready at -> ${BUILD_DIR}/metadata_dist/"
  echo ""
  echo "To upload IPA using Apple ID credentials, execute:"
  echo "  xcrun altool --upload-app -f \"${IPA_PATH}\" -t ios -u <APPLE_ID> -p <APP_SPECIFIC_PASSWORD>"
  echo ""
ENV_FILE="${PROJECT_DIR}/.keys/appstore_connect.env"
if [ -f "${ENV_FILE}" ]; then
  source "${ENV_FILE}"
fi

if [ -n "${APPSTORE_KEY_ID}" ] && [ -n "${APPSTORE_ISSUER_ID}" ]; then
  echo "App Store Connect API Key & Issuer ID Loaded:"
  echo "  - Key ID: ${APPSTORE_KEY_ID}"
  echo "  - Issuer ID: ${APPSTORE_ISSUER_ID}"
  echo ""
  echo "Run One-Shot Direct Upload to App Store Connect:"
  echo "  xcrun altool --upload-app -f \"${IPA_PATH}\" -t ios --apiKey \"${APPSTORE_KEY_ID}\" --apiIssuer \"${APPSTORE_ISSUER_ID}\""
else
  echo "To upload IPA with App Store Connect API Key, run:"
  echo "  xcrun altool --upload-app -f \"${IPA_PATH}\" -t ios --apiKey XFW954Z6SB --apiIssuer <YOUR_ISSUER_ID>"
fi
  echo ""
  echo "Or open Xcode Organizer directly:"
  echo "  open \"${ARCHIVE_PATH}\""
else
  echo "❌ ERROR: IPA compilation failed."
  exit 1
fi
