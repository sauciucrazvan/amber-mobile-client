# 07 - Settings

Local app settings. Account settings are in [06-account.md](06-account.md).

## Sections

- **Devices**: choose the microphone, camera, and speaker. On mobile, the camera choice becomes front or back.
- **Appearance**: theme (light or dark) and font scale. The desktop offers font scales from 0.8x to 2x.
- **About**: app version, build info, and links to the project.
- **Legal**: terms and privacy text (shared with the auth screens).

## Storage

- Store settings locally in a key-value store (for example `shared_preferences`). They are per device and do not sync.
- Apply theme and font scale immediately, without a restart.

## Excluded

- Start on boot, tray, and the desktop updater have no mobile equivalent. See [08-desktop-only.md](08-desktop-only.md).
- The developer server switcher in About is excluded from the first version.

## Acceptance

- Theme and font scale changes apply right away and persist across restarts.
- Device choices are used by the next call.
