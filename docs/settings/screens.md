# Settings: Screens and storage

Sources: `lib/features/settings/`, `lib/features/calls/bloc/call_devices_cubit.dart`, `lib/core/theme/appearance_cubit.dart`

The settings screen opens from the gear in the chats header. It is one page with four sections, as in plan 07.

## Appearance

- **Dark theme:** a switch. It applies at once, without a restart.
- **Scaling:** the font scale, from 0.8x to 2x, as on the desktop. It applies at once.

## Devices

These apply from the next call.

- **Camera:** front or back. The default is front.
- **Speaker:** speaker or earpiece. The default is speaker. Calls can still switch it during the call.
- **Microphone:** shown, with a note that the phone's default microphone is used. Phones do not let an app choose between microphones, so the desktop's choice has no mobile equivalent.

## About

- The version and build number, such as `1.0.0 (1)`.
- A link to the project on GitHub.

The developer server switcher is left out, as the plan says.

## Legal

The Terms & Conditions and the Privacy Policy, from the same dialogs as the sign-in screens.

## Storage

Settings are per device and do not sync.

| Setting | Key | Values |
|---------|-----|--------|
| Theme | `amber.theme` | `light`, `dark` |
| Font scale | `amber.fontScale` | a double |
| Call camera | `amber.callCamera` | `front`, `back` |
| Call audio output | `amber.callAudioOutput` | `speaker`, `earpiece` |
