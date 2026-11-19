# Settings: Screens and storage

Sources: `lib/features/settings/`, `lib/features/calls/bloc/call_devices_cubit.dart`, `lib/core/theme/appearance_cubit.dart`

Settings is the third tab in the bottom bar: Requests, Chats (the default), Settings. It is one scrolling page with sections, as in plan 07.

## Appearance

- **Dark theme:** a switch. It applies at once, without a restart.
- **Scaling:** the font scale, from 0.8x to 2x, as on the desktop. It applies at once.

## Devices

These apply from the next call.

- **Camera:** front or back. The default is front.
- **Speaker:** speaker or earpiece. The default is speaker. Calls can still switch it during the call.
- **Microphone:** shown, with a note that the phone's default microphone is used. Phones do not let an app choose between microphones, so the desktop's choice has no mobile equivalent.

## Language

A chooser with each language named in itself: English, Română, Deutsch, Français, Español, 中文, 日本語 and Italiano. Choosing one reloads every string at once, and the choice is saved, so the next launch uses it. Without a saved choice, the app follows the device language.

## Contacts

Blocked accounts. The list used to sit in the chats header, and is opened from here.

## About

- The version and build number, such as `1.0.0 (1)`.

The developer server switcher is left out, as the plan says. The project link was removed.

## Legal

The Terms & Conditions and the Privacy Policy, from the same dialogs as the sign-in screens.

## Storage

Settings are per device and do not sync.

| Setting | Key | Values |
|---------|-----|--------|
| Theme | `amber.theme` | `light`, `dark` |
| Language | `amber.language` | a supported language code, such as `ro` |
| Font scale | `amber.fontScale` | a double |
| Call camera | `amber.callCamera` | `front`, `back` |
| Call audio output | `amber.callAudioOutput` | `speaker`, `earpiece` |
