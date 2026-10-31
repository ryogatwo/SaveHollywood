# Initial 2.7.0 validation — October 30, 2026

## Verified

- Xcode 26.3 (17C529), macOS SDK 26.2; Release build succeeded.
- Runtime smoke tests ran natively on Apple Silicon, macOS 15.7.2 (24G325).
- `lipo` verified arm64 and x86_64 in the screen saver and installer.
- `vtool` reports macOS minimum 11.0 and SDK 26.2 for both saver slices.
- Both English and French configuration nibs are present; default options nib
  loaded successfully in the runtime test.
- Fractional custom volume 0.375 survives settings load/serialization.
- Legacy keyed and new secure-keyed resume archives round-trip through the
  restricted-class decoder with URL and CMTime data intact.
- Runtime tests loaded the actual compiled saver, generated a short H.264 movie,
  confirmed a ready player item and advancing playback clock, exercised repeated
  start/stop, metadata callbacks, stop/restart and timer cleanup.
- Test settings use a unique bundle/preferences identifier and temporary movie;
  tests did not install or alter the user's existing screen saver.
- Saver and installer signed with Developer ID Application; team TFU4LPPSM3.
  Hardened runtime and secure timestamps enabled; strict signature checks passed.
- Apple accepted the installer submission:
  `52588042-8a54-4294-84f4-7655ef4d69c5`.
- Apple accepted the signed disk image submission:
  `c519ee88-c4fc-4894-ac08-51e6aac5adf8`.
- Installer and disk image tickets stapled and validated; both Gatekeeper checks
  returned `accepted`, source `Notarized Developer ID`.
- Binary resources include LICENSE.txt and NOTICE.md before signing.
- Original upstream revision: `435570bd65e70f4a7b3b8c570b989174b62b8755`.
  The original history is retained via an ancestry-only merge after the source
  snapshot import and modernization commit; the upstream remote is preserved.

## Limits and follow-up

This initial release is marked **pre-release** pending broader manual testing.
A current SDK build is not evidence of full macOS 26 runtime compatibility.
The following have not been verified in this session:

- Actual System Settings installation and full-screen ScreenSaverEngine sessions.
- macOS 26, macOS 11–14, or runtime execution on Intel hardware.
- Multiple displays, sleep/wake, protected folders, external/removable media,
  prolonged playback, audible output, visual scaling, or French UI rendering.
- User interaction with the installer, backup restoration and error dialogs.

Legacy file drag/drop pasteboard calls remain deprecated in the SDK. The media
loader still uses AVFoundation's Objective-C loading interfaces; a larger async
media pipeline rewrite is outside this compatibility update. File access depends
on macOS screen saver host permissions. No new file-access entitlement or
privacy bypass is claimed. No certificate, private key, notarization password,
or other signing secret is stored in this repository or its release files.

The standalone ZIP contains the same signed saver submitted inside the accepted
installer. Prefer the stapled disk image for offline Gatekeeper verification.
