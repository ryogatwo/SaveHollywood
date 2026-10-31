SaveHollywood 2.7.2 (13) fixes audio continuing after exiting a full-screen preview or switching screen savers.

- Stops playback on system dismissal notifications and when a view leaves its window, including hosts that omit `stopAnimation`.
- Cleanup runs even when macOS has already reset the animation flag. Players are paused, muted and disconnected from their media; retired players cannot keep producing audio.
- Movie replacement also stops the previous player, and late completion callbacks cannot restart dismissed playback.
- Retains the separate Settings thumbnail lifecycle, universal Apple Silicon/Intel binaries, and macOS 11 deployment target.
- Regression tests generate a movie with H.264 video and AAC audio, retain its players, and verify media release after each shutdown path.

Download **SaveHollywood-2.7.2-universal.dmg**, open **Install SaveHollywood.app**, and click **Install Screensaver**. Existing copies are backed up and preferences are preserved. Close System Settings before upgrading. Restart your Mac once if an older cached copy continues playing audio; reopening Settings alone may retain the older screen-saver host.

The saver, installer and disk image are Developer ID signed. The installer and disk image are Apple notarized with stapled tickets. The release includes the signed saver ZIP, checksums and notarization receipts.

This remains a pre-release pending wider Intel, multi-display and OS testing. See VALIDATION.md for exact checks and limitations. Original SaveHollywood by Stephane Sudre / WhiteBox; independent derivative distributed under the retained upstream license and attribution, without WhiteBox endorsement.
