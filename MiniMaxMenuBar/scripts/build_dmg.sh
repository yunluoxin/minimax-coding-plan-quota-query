#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

APP_NAME="MiniMaxMenuBar"
VERSION=$(grep "MARKETING_VERSION" project.yml | head -1 | sed 's/.*: *"\([^"]*\)"/\1/')
DMG_NAME="${APP_NAME}-${VERSION}"

echo "Building ${DMG_NAME}..."

xcodebuild -project MiniMaxMenuBar.xcodeproj -scheme MiniMaxMenuBar -configuration Release build \
  CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO \
  BUILD_DIR="$(pwd)/.build" 2>&1 | tail -5

APP_PATH="$(pwd)/.build/Release/${APP_NAME}.app"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

echo "Creating DMG..."
DMG_TEMP="/tmp/${DMG_NAME}-temp.dmg"
DMG_FINAL="${DMG_NAME}.dmg"

hdiutil create "$DMG_TEMP" -size 100M -ov -volname "$APP_NAME" -fs HFS+ -srcfolder "$APP_PATH" -format UDRW -quiet

hdiutil convert "$DMG_TEMP" -format UDZO -o "$DMG_FINAL" -quiet

rm -f "$DMG_TEMP"

echo "Done: $DMG_FINAL"
ls -lh "$DMG_FINAL"
