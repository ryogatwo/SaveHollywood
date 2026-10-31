# SaveHollywood 2.7.3 validation — October 31, 2026

## Options appearance

- Observed the user's live Options sheet on macOS 15.7.2: enabled controls were
  visibly washed out while accessibility correctly reported them as enabled.
- Reproduced the drawing fault with an oversized dirty rectangle: SHSecondaryBox
  painted outside its bounds. Modern AppKit allows dirty rectangles beyond a
  view's bounds; the legacy section fill covered previously drawn siblings.
- SHSecondaryBox now clips its drawing, including the border, to its bounds.
  SHLightGrayBackgroundView limits its fill to the bounds/dirty-rect intersection.
- A pixel regression verifies both that neighboring pixels stay untouched and
  the intended background still draws inside the section. Passed after the fix.
- The audio/video and lifecycle regression suite passed again on macOS 15.7.2.
- Universal architecture and strict signature checks passed.
- Apple accepted installer submission `2a56edfe-4825-4577-9b93-48317f8e58ed` and disk image
  submission `05909253-74cf-420e-9ab8-08d802a47b17`; stapling/validation and Gatekeeper passed.
- Installed the signed update on the host with the previous copy backed up.
- Refreshed the cached host, reopened the actual System Settings Options sheet,
  and visually verified normal contrast for enabled buttons, radio choices,
  checkboxes and movie rows. Dependent controls retain their disabled styling.

Drawing behavior reference: [Apple NSView clipsToBounds documentation](https://developer.apple.com/documentation/appkit/nsview/clipstobounds).

# SaveHollywood 2.7.2 validation — October 31, 2026

## Audio shutdown regression

A user reported video audio continuing after leaving a full-screen preview and
changing screen savers. The previous regression suite did not include an audio
track or emulate a host that omits/reset animation lifecycle callbacks.

- Before the fix, the new retained-player test failed when the host reported
  `isAnimating == NO` before invoking cleanup.
- The updated test generates H.264 video with an AAC audio track and verifies
  a ready player item and advancing playback clock before testing shutdown.
- Cleanup now runs independently of the host animation flag. It also handles
  view removal and distributed `com.apple.screensaver.willstop` / `didstop`
  notifications for full-screen instances, without stopping a separate preview.
- Retired players are paused, muted and disconnected from their items/layers.
  Tests hold strong player references and require that dismissed, detached and
  replaced players are muted with no current media item. Late callbacks cannot
  restart playback. AVFoundation can report a stale desired rate for an empty
  player in the VM; silence is verified by mute plus absence of media instead.
- Release build and regression tests passed on Apple Silicon macOS 15.7.2.
- The same compiled saver and audio regression executable passed in the macOS
  27.2 (26B123) Parallels VM as its desktop user. The VM retained a stale desired
  rate for one empty player; mute and media-detachment assertions passed.
- Universal arm64/x86_64 binaries passed strict signature/architecture checks.
- Apple accepted installer submission `4672d21a-0882-42e8-8d50-4951eab8e292` and disk image
  submission `25c92909-936d-4b3d-96f2-64a0ff987e78`. Both tickets were stapled and validated,
  and Gatekeeper accepted both as Notarized Developer ID.

The dismissal tests simulate lifecycle signals against the actual compiled saver.
They do not constitute a recording of audible output or a new physical-display
System Settings session. Existing cached 2.7.1 host instances must be replaced;
restart the Mac once after upgrading if an older instance keeps playing audio.

# SaveHollywood 2.7.1 validation — October 30, 2026

## macOS 27.2 guest validation

Environment: Apple Silicon host, Parallels Desktop 27.1.0 (58756), new macOS
27.2 (26B123) VM with 4 CPUs and 8 GB RAM, Parallels Tools installed.

- The 2.7.0 published disk image downloaded inside the VM and matched its
  published SHA-256 checksum. Strict signature checks passed; Gatekeeper
  returned `accepted`, source `Notarized Developer ID`.
- The installer launched normally and installed into the test user's
  `~/Library/Screen Savers`. SaveHollywood appeared under Wallpaper → Screen
  Saver → Custom → Other. Its native configuration sheet loaded successfully.
- A generated animated H.264 test movie was selected using the native file
  picker and saved through Options. The full-screen preview launched from
  System Settings displayed the changing movie frames and continued looping.
  Escape returned to settings normally.
- The isolated smoke-test executable also passed on the guest: bundle loading,
  configuration nib, fractional volume, legacy/new secure resume archives,
  ready player item, advancing playback clock, metadata callbacks, and repeated
  start/stop with timer cleanup. Tests used a temporary bundle identifier.
- Found and fixed an installer navigation issue: on macOS 26 and later the
  old Screen Saver settings URL opened General. Version 2.7.1 uses the verified
  `com.apple.Wallpaper-Settings.extension` identifier and describes the new path.
- Version 2.7.1 has universal arm64/x86_64 saver and installer binaries, strict
  signature verification, and hardened runtime with secure timestamps.
- Apple accepted the 2.7.1 installer submission
  `8985eab3-492b-4708-8615-fb184d26332d` and disk image submission
  `57ad17e5-2710-424f-8e6a-2211879c9d53`. Tickets were stapled/validated and
  Gatekeeper accepted both. The guest also accepted the 2.7.1 installer.
- The native installer successfully upgraded the guest from 2.7.0 to 2.7.1,
  created the prior-version backup, and displayed the corrected instructions.
  Backups now use `.saver.backup` so macOS does not register them as duplicate
  installed screen savers; the earlier VM test backup was renamed accordingly.
  The same runtime suite passed again against the upgraded bundle.

The inline System Settings thumbnail was initially stale after changing the movie.
Reopening System Settings refreshed it and displayed the animated test clip.
Both inline and full-screen previews were then visibly verified in the guest.
Close and reopen System Settings if it caches a previous screen-saver state.

Remaining checks: Intel hardware execution, macOS 11–14 and 26 runtime,
multiple physical displays, sleep/wake, audible output, protected folders,
external media, French UI rendering, and prolonged playback. VM graphics are
not equivalent to physical Mac display testing. This remains a pre-release.

## Original 2.7.0 validation

### Verified

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

### Initial limits and follow-up

This initial release is marked **pre-release** pending broader manual testing.
A current SDK build is not evidence of full macOS 26 runtime compatibility.
The following were not verified at the time of the initial 2.7.0 release
(the later VM checks above supersede overlapping items):

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
