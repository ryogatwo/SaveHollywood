SaveHollywood 2.7.0 (11) modernizes the original Stephane Sudre / WhiteBox screen saver for Apple Silicon and Intel Macs.

- Universal arm64 + x86_64 `.saver`, macOS 11 minimum, built with Xcode 26.3 and the macOS 26.2 SDK.
- Current SDK/framework references and shared Xcode build scheme.
- Metadata callback, repeated start/stop, resume archive and fractional volume fixes.
- Original settings identifier, English/French options and original attribution retained.

Download **SaveHollywood-2.7.0-universal.dmg**, open **Install SaveHollywood.app**, and click **Install Screensaver**. Select SaveHollywood in macOS Screen Saver settings. Existing copies are backed up and preferences are preserved.

The installer, screen saver and disk image are Developer ID signed. Apple notarization and Gatekeeper verification results are recorded in VALIDATION.md. The installer and disk image carry stapled tickets. A signed screen saver ZIP and SHA-256 checksums are also provided.

Validated with a local runtime smoke test including actual generated movie playback and both architecture slices. Wider OS, Intel hardware and multi-display testing remain outstanding; see VALIDATION.md. This is an independent derivative of packagesdev/savehollywood, distributed under its original source-header license, with no WhiteBox endorsement.
