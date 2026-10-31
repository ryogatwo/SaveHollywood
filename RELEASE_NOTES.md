SaveHollywood 2.7.3 (14) fixes enabled options looking grayed out on modern macOS.

- Section backgrounds no longer paint over neighboring buttons, labels or movie rows.
- Genuine dependencies remain: Custom enables the volume slider, Actual Size enables Random position, and Show title & copyright enables metadata controls.
- Adds a pixel rendering regression that fails for the old out-of-bounds drawing and verifies the corrected fill remains visible inside each section.
- Retains the 2.7.2 audio shutdown fix and universal Apple Silicon/Intel build.

Download **SaveHollywood-2.7.3-universal.dmg**, open **Install SaveHollywood.app**, and click **Install Screensaver**. Existing copies are backed up and preferences are preserved. Close System Settings before upgrading. Restart your Mac once if an older cached copy continues playing audio; reopening Settings alone may retain the older screen-saver host.

The saver, installer and disk image are Developer ID signed. The installer and disk image are Apple notarized with stapled tickets. The release includes the signed saver ZIP, checksums and notarization receipts.

This remains a pre-release pending wider Intel, multi-display and OS testing. See VALIDATION.md for exact checks and limitations. Original SaveHollywood by Stephane Sudre / WhiteBox; independent derivative distributed under the retained upstream license and attribution, without WhiteBox endorsement.
