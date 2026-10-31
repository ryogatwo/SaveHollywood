# SaveHollywood — modern macOS build

Play local videos as your macOS screen saver. This independent derivative of
[SaveHollywood by Stephane Sudre / WhiteBox](https://github.com/packagesdev/savehollywood)
builds as a universal **Apple Silicon (arm64) + Intel (x86_64)** `.saver` bundle.
The deployment target is **macOS 11 or later**. See [NOTICE.md](NOTICE.md) for
upstream provenance and [LICENSE](LICENSE) for redistribution conditions.

## Install

Download the disk image from [Releases](https://github.com/ryogatwo/SaveHollywood/releases),
open **Install SaveHollywood.app**, and click **Install Screensaver**.
On macOS 26 or later, open **System Settings → Wallpaper → Screen Saver**, choose **Custom**, then select SaveHollywood under **Other**. On earlier releases, select SaveHollywood in **System Settings → Screen Saver** and open its options
to choose videos or folders. The installer keeps an existing copy as a uniquely
named backup in `~/Library/Screen Savers`; remove that backup after testing.
Close and reopen System Settings if it caches the old screen saver.

The release also provides a signed `.saver` ZIP for direct installation. The
notarized disk image is the preferred download because it carries a stapled Apple
approval ticket for offline verification. The `.saver` retains its Developer ID
signature; the ZIP itself cannot carry a stapled ticket.

The original settings domain `fr.whitebox.SaveHollywood` is retained, so existing
preferences normally carry over. macOS privacy rules can restrict media folders
in the screen saver host. If playback is blank, try a locally downloaded video
in an accessible folder and reselect it in Options. Protected/DRM media and
remote streaming URLs are not supported. Playback uses AVFoundation codecs.

## What changed in 2.7.1 (12)

- Corrected installer navigation and instructions for macOS 26/27 Wallpaper settings; tested installation, options, runtime playback and the full-screen system preview in a macOS 27.2 VM.

- Universal Apple Silicon/Intel build, current installed SDK, macOS 11 minimum,
  SDK-relative frameworks, shared Xcode scheme and reproducible build scripts.
- Developer ID signing, hardened runtime, secure timestamps, notarized installer
  app and disk image, architecture/signature checks, and SHA-256 checksums.
- Removed obsolete Gestalt version queries and pre-Sierra unkeyed archive paths;
  resume data uses restricted-class decoding and secure keyed encoding.
- Main-thread metadata updates ignore stale player completions after stop/switch;
  repeated start/stop calls avoid duplicate timers and observers, and end-of-item
  notifications no longer block the posting thread waiting for the main thread.
- Fractional custom volume settings survive reload; settings objects release
  retained data; unscaled videos respect their track orientation.
- Updated deprecated AppKit constants and color/date calls. The legacy file
  drag/drop API remains for now and emits deprecation warnings with Xcode 26.

## Build and test

Install full Xcode and select it as the active developer directory. Xcode 26.3
with the macOS 26.2 SDK was used for the initial verification.

```sh
bash scripts/build.sh
bash scripts/test.sh
```

The development build is ad-hoc signed and appears at
`build/DerivedData/Build/Products/Release/SaveHollywood.saver`.
The build uses both architectures even on a single-architecture host.
The smoke test loads a temporary copy under a unique preferences identifier;
it checks nib loading, fractional volume, old/new resume archives, start/stop,
generated video playback and metadata stop/restart. It needs a macOS GUI session
and access to macOS video services. It does not install or change the user's saver.

In Xcode, open `SaveHollywood.xcodeproj` and select the shared SaveHollywood
scheme. Default signing is ad-hoc. Release signing is performed explicitly by
the scripts below; no personal certificate or team is hard-coded into the project.

## Sign, notarize, package

Use an existing **Developer ID Application** identity with its private key in
Keychain. A development certificate is not a distribution substitute.

```sh
security find-identity -v -p codesigning
export APPLICATION_SIGNING_IDENTITY='Developer ID Application: Your Name (TEAMID)'
export NOTARY_KEYCHAIN_PROFILE='YourExistingNotaryProfile'
bash scripts/release.sh
```

The initial release uses the same local Keychain identity and notarization profile
as the Desktop Ponies release. Secrets remain in Keychain; none belong in this
repository, shell arguments, logs, or GitHub Actions artifacts. If no profile exists,
create one interactively with `xcrun notarytool store-credentials PROFILE_NAME`.
See Apple's [notarization guide](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
and [Developer ID certificate guide](https://developer.apple.com/help/account/certificates/create-developer-id-certificates/).

The release script builds, includes attribution inside the bundle, signs the
`.saver`, compiles and signs a universal installer app, submits the app ZIP to
Apple and requires **Accepted**, staples and validates the app ticket, verifies
Gatekeeper acceptance, creates/signs the disk image, notarizes/staples it, checks
Gatekeeper again, and writes checksums. It uses the existing Keychain profile
without extracting its credentials. Each failed verification stops the script.
Do not change any signed bundle after signing. Rebuild and rerun the pipeline
if source or bundled resources change.

Outputs are in `dist/`: disk image, signed `.saver`, `.saver` ZIP, checksums and
Apple's JSON receipts. Release receipts contain submission IDs, not credentials.
If Apple rejects a submission, inspect its log using the ID in the JSON receipt:

```sh
xcrun notarytool log SUBMISSION_ID --keychain-profile "$NOTARY_KEYCHAIN_PROFILE"
```

## Publish a release

After the checks and runtime review pass, commit the source and create a tag.
Publish the disk image, ZIP and checksums from that exact source revision:

```sh
git tag v2.7.1
git push origin main --tags
gh release create v2.7.1 --repo ryogatwo/SaveHollywood \
  --title 'SaveHollywood 2.7.1 — Apple Silicon and Intel' \
  --notes-file RELEASE_NOTES.md \
  dist/SaveHollywood-2.7.1-universal.dmg \
  dist/SaveHollywood-2.7.1-saver.zip dist/SHA256SUMS.txt
```

GitHub Actions builds and smoke-tests an ad-hoc development artifact. Public
Developer ID releases run locally using Keychain; there are no signing secrets
in CI. Review [VALIDATION.md](VALIDATION.md) for measured results and limits.

## Manual compatibility checks

Before claiming broader compatibility, test actual Screen Saver previews and
full-screen sessions on Apple Silicon and Intel Macs, including multi-display
placement, sleep/wake, repeated start/stop, sound/volume, folder permissions,
resume playback, shuffled folders, scaling and metadata, and both English and
French options. Building both architectures does not verify all OS/host behavior.
The current ScreenSaver framework host remains the integration point; this is
not a migration to a different screen saver extension model.
