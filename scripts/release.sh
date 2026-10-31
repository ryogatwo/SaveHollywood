#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${APPLICATION_SIGNING_IDENTITY:?Set your Developer ID Application identity}"
: "${NOTARY_KEYCHAIN_PROFILE:?Set your existing notarytool Keychain profile}"
export APPLICATION_SIGNING_IDENTITY
bash scripts/build.sh
stage=$(mktemp -d "${TMPDIR:-/tmp}/savehollywood-release.XXXXXX")
trap 'rm -rf "$stage"' EXIT
mkdir -p dist
app="$stage/Install SaveHollywood.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
ditto build/DerivedData/Build/Products/Release/SaveHollywood.saver "$app/Contents/Resources/SaveHollywood.saver"
cp LICENSE NOTICE.md "$app/Contents/Resources/"
cat > "$app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>com.ryogatwo.SaveHollywoodInstaller</string>
<key>CFBundleName</key><string>Install SaveHollywood</string>
<key>CFBundleExecutable</key><string>Installer</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>2.7.2</string>
<key>CFBundleVersion</key><string>13</string>
<key>LSMinimumSystemVersion</key><string>11.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
xcrun clang -fobjc-arc -O2 -Wall -Wextra -Wno-unused-parameter \
  -arch arm64 -arch x86_64 -mmacosx-version-min=11.0 \
  -framework Cocoa Installer/Installer.m -o "$app/Contents/MacOS/Installer"
codesign --force --options runtime --timestamp --sign "$APPLICATION_SIGNING_IDENTITY" "$app"
lipo "$app/Contents/MacOS/Installer" -verify_arch arm64 x86_64
ditto -c -k --sequesterRsrc --keepParent "$app" "$stage/notarization-upload.zip"
xcrun notarytool submit "$stage/notarization-upload.zip" --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" --wait --output-format json > dist/notarization-app.json
[[ "$(plutil -extract status raw -o - dist/notarization-app.json)" == Accepted ]]
xcrun stapler staple "$app"
xcrun stapler validate "$app"
codesign --verify --deep --strict "$app"
spctl --assess --type execute --verbose=2 "$app"
mkdir "$stage/image"
ditto "$app" "$stage/image/Install SaveHollywood.app"
cp LICENSE NOTICE.md "$stage/image/"
printf '%s\n' 'Open Install SaveHollywood.app and click Install Screensaver.' > "$stage/image/READ ME.txt"
dmg=dist/SaveHollywood-2.7.2-universal.dmg
hdiutil create -volname 'SaveHollywood 2.7.2' -srcfolder "$stage/image" -format UDZO -ov "$dmg"
codesign --force --timestamp --sign "$APPLICATION_SIGNING_IDENTITY" "$dmg"
xcrun notarytool submit "$dmg" --keychain-profile "$NOTARY_KEYCHAIN_PROFILE" --wait --output-format json > dist/notarization-dmg.json
[[ "$(plutil -extract status raw -o - dist/notarization-dmg.json)" == Accepted ]]
xcrun stapler staple "$dmg"
xcrun stapler validate "$dmg"
spctl --assess --type open --context context:primary-signature --verbose=2 "$dmg"
# Also provide the signed .saver directly; its notarization is covered by the app submission.
ditto build/DerivedData/Build/Products/Release/SaveHollywood.saver dist/SaveHollywood.saver
(cd dist && ditto -c -k --sequesterRsrc --keepParent SaveHollywood.saver SaveHollywood-2.7.2-saver.zip)
(cd dist && shasum -a 256 SaveHollywood-2.7.2-universal.dmg SaveHollywood-2.7.2-saver.zip > SHA256SUMS.txt)
echo 'Apple accepted both submissions; installer and disk-image tickets validated.'
