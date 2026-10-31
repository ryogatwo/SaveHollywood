#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
stage=$(mktemp -d "${TMPDIR:-/tmp}/savehollywood-test.XXXXXX")
trap 'rm -rf "$stage"' EXIT
ditto build/DerivedData/Build/Products/Release/SaveHollywood.saver "$stage/SaveHollywood.saver"
# Isolate ScreenSaverDefaults from the user's installed saver.
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier org.ryogatwo.SaveHollywood.test.$(uuidgen)" "$stage/SaveHollywood.saver/Contents/Info.plist"
codesign --force --sign - "$stage/SaveHollywood.saver"
xcrun clang -fobjc-arc -O1 -I SaveHollywood -framework Cocoa -framework ScreenSaver \
  -framework AVFoundation -framework CoreVideo -framework CoreMedia \
  Tests/Smoke.m -o "$stage/smoke"
"$stage/smoke" "$stage/SaveHollywood.saver"

xcrun clang -fobjc-arc -O1 -framework Cocoa Tests/Appearance.m -o "$stage/appearance"
"$stage/appearance" "$stage/SaveHollywood.saver"
