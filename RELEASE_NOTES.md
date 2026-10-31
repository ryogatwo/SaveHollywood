SaveHollywood 2.7.1 (12) has been tested in a macOS 27.2 Apple Silicon VM.

- Fixes the installer shortcut and instructions for macOS 26 and later: System Settings → Wallpaper → Screen Saver → Custom → Other.
- Retains universal Apple Silicon/Intel binaries and macOS 11 deployment target.
- Passed runtime tests on macOS 27.2: bundle and options loading, fractional volume, old/new resume archives, video playback clock, metadata callbacks and repeated start/stop.
- Native System Settings options and playback checks are recorded in VALIDATION.md.

Download **SaveHollywood-2.7.1-universal.dmg**, open **Install SaveHollywood.app**, and click **Install Screensaver**. Existing copies are backed up, and preferences are preserved.

The screen saver, installer and disk image are Developer ID signed. The installer and disk image are Apple notarized and carry stapled tickets. A signed screen saver ZIP, checksums and notarization receipts are also provided.

This remains a pre-release pending wider Intel, multi-display and OS testing. VM graphics are not equivalent to physical Mac display testing. Original SaveHollywood by Stephane Sudre / WhiteBox; independent derivative distributed under the retained upstream license and attribution, without WhiteBox endorsement.
