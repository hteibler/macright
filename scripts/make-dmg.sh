#!/bin/zsh
# Build, sign (Developer ID), notarize and staple macright, then package a DMG.
# Needs a notarytool keychain profile: xcrun notarytool store-credentials macright-notary
set -euo pipefail
cd "$(dirname "$0")/.."

PROFILE="${NOTARY_PROFILE:-macright-notary}"
IDENTITY="Developer ID Application: HERBERT TEIBLER (V8583J8736)"
VERSION="$(sed -n 's/.*MARKETING_VERSION: "\(.*\)"/\1/p' project.yml | head -1)"
APP="build/Build/Products/Release/macright.app"
DMG="dist/macright-$VERSION.dmg"

xcodegen generate
xcodebuild -project Macright.xcodeproj -scheme Macright -configuration Release \
    -derivedDataPath build clean build | tail -1

codesign --verify --deep --strict --verbose=2 "$APP"

mkdir -p dist && rm -f "$DMG"
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "macright" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
rm -rf "$STAGE"
codesign --force --sign "$IDENTITY" "$DMG"

xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"
spctl --assess --type open --context context:primary-signature -v "$DMG"
echo "Done: $DMG"
