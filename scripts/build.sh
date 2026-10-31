#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
xcodebuild -project SaveHollywood.xcodeproj -scheme SaveHollywood \
  -configuration "${CONFIGURATION:-Release}" -derivedDataPath build/DerivedData \
  ARCHS='arm64 x86_64' ONLY_ACTIVE_ARCH=NO CODE_SIGNING_ALLOWED=NO build
product="build/DerivedData/Build/Products/${CONFIGURATION:-Release}/SaveHollywood.saver"
# Include redistribution conditions in every binary distribution before signing.
cp LICENSE "$product/Contents/Resources/LICENSE.txt"
cp NOTICE.md "$product/Contents/Resources/NOTICE.md"
if [[ -n "${APPLICATION_SIGNING_IDENTITY:-}" ]]; then
  [[ "$APPLICATION_SIGNING_IDENTITY" == 'Developer ID Application:'* ]] || exit 2
  codesign --force --options runtime --timestamp --sign "$APPLICATION_SIGNING_IDENTITY" "$product"
else
  codesign --force --sign - "$product"
fi
bash scripts/verify.sh "$product"
