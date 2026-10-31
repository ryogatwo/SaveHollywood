#!/bin/bash
set -euo pipefail
bundle="${1:?Supply a .saver bundle}"
binary="$bundle/Contents/MacOS/SaveHollywood"
lipo "$binary" -verify_arch arm64 x86_64
file "$binary"
codesign --verify --strict --verbose=2 "$bundle"
plutil -lint "$bundle/Contents/Info.plist"
[[ "$(/usr/libexec/PlistBuddy -c 'Print :NSPrincipalClass' "$bundle/Contents/Info.plist")" == SaveHollywoodView ]]
[[ -s "$bundle/Contents/Resources/LICENSE.txt" ]]
[[ -f "$bundle/Contents/Resources/en.lproj/SHConfigurationWindowController.nib" ]]
[[ -f "$bundle/Contents/Resources/fr.lproj/SHConfigurationWindowController.nib" ]]
