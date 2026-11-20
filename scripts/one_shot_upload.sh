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
  -allowProvisioningUpdates \
  -quiet

echo ""
echo "================================================================="
echo "📱 3/4: Exporting Signed IPA Package..."
echo "================================================================="
xcodebuild -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -exportOptionsPlist "${EXPORT_OPTIONS}" \
  -allowProvisioningUpdates \
  -quiet

echo ""
echo ""
echo "================================================================="
echo "🌐 4/5: Syncing Metadata to App Store Connect REST API..."
echo "================================================================="
python3 "${PROJECT_DIR}/scripts/upload_metadata_api.py"

echo ""
echo "================================================================="
echo "✅ 5/5: Uploading IPA Package to App Store Connect..."
echo "================================================================="
ENV_FILE="${PROJECT_DIR}/.keys/appstore_connect.env"
if [ -f "${ENV_FILE}" ]; then
  source "${ENV_FILE}"
fi

if [ -n "${APPSTORE_KEY_ID}" ] && [ -n "${APPSTORE_ISSUER_ID}" ]; then
  echo "Uploading with Key ID ${APPSTORE_KEY_ID} & Issuer ID ${APPSTORE_ISSUER_ID}..."
  mkdir -p ~/.private_keys
  cp "${PROJECT_DIR}/.keys/AuthKey_${APPSTORE_KEY_ID}.p8" ~/.private_keys/ 2>/dev/null || true
  xcrun altool --upload-app -f "${IPA_PATH}" -t ios --apiKey "${APPSTORE_KEY_ID}" --apiIssuer "${APPSTORE_ISSUER_ID}"
  echo ""
  echo "🎉 One-Shot Binary & Metadata Upload Successfully Completed!"
else
  echo "SUCCESS: IPA Package Ready at -> ${IPA_PATH}"
  echo "Metadata Configured at -> ${BUILD_DIR}/metadata_dist/"
  echo "Run: xcrun altool --upload-app -f \"${IPA_PATH}\" -t ios --apiKey XFW954Z6SB --apiIssuer <ISSUER_ID>"
fi
