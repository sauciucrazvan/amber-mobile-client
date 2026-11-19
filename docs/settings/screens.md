# Settings: Screens and storage

Sources: `lib/features/settings/`, `lib/features/account/view/account_settings.dart`, `lib/features/calls/bloc/call_devices_cubit.dart`, `lib/core/theme/appearance_cubit.dart`

The Settings tab lists four categories, as on the desktop. Each opens its own page, with the settings grouped on it.

| Category | Page | What it holds |
|----------|------|---------------|
| General | `GeneralPage` | Appearance (dark theme, font scale) and Language |
| Account | `AccountPage` | Your avatar (tap it to change), Account details (name, email, bio), Security (password), Privacy (privacy switch, blocked contacts, request your data), Danger zone (delete) |
| Devices | `DevicesPage` | Camera, speaker, and a note about the microphone |
| About | `AboutPage` | Version, and Legal (Terms and Privacy) |

## General

- **Dark theme:** a switch. It applies at once.
- **Scaling:** the font scale, from 0.8x to 2x. It applies at once.
- **Language:** the menu lists each language in its own name. Choosing one reloads every string at once, and the choice is saved, so the next launch uses it. Without a saved choice, the app follows the device language.

## Account

The avatar at the top changes the picture: pick a JPEG, PNG or WebP image up to 5 MB, confirm, and upload. The bio shows in the same box as on the profile. Each setting saves to the server:

| Setting | Saves with | Notes |
|---------|-----------|-------|
| Name | `PATCH /account/v1/modify/fullname` | The server allows one change a week. |
| Bio | `PATCH /account/v1/modify/bio` | Up to 256 characters, checked before sending. Shown in the profile box. |
| Email | `POST /account/v1/modify/email/request`, `/confirm`, `/verify` | A three-step dialog. The confirm step appears only when the server asks for the current email's code. |
| Password | `PATCH /account/v1/modify/password` | Checks the confirmation matches. On success the app signs out, because the server rotates the session. |
| Let people find you | `PATCH /account/v1/settings/privacy` | The `allow_add_by_email` switch. A setting the server does not send counts as on. |
| Blocked contacts | Opens the blocked list | Under Privacy. |
| Request your data | `POST /account/v1/request/data` | Under Privacy. Sent by email, one request a week. |
| Delete account | `DELETE /account/v1/delete` | Asks for the password, then confirms once more. On success the session is cleared and the app returns to sign-in. Device settings stay. |

Sign-out is still in My Profile.

## Devices

These apply from the next call.

- **Camera:** front or back. The default is front.
- **Speaker:** speaker or earpiece. The default is speaker. Calls can still switch it during the call.
- **Microphone:** shown, with a note that the phone's default microphone is used. Phones do not let an app choose between microphones.

## About

The version and build number, such as `1.0.0 (1)`. Legal documents (Terms and Privacy) come from the same dialogs as the sign-in screens. The developer server switcher is left out, as the plan says, and so is the project link.

## Storage

Settings are per device and do not sync.

| Setting | Key | Values |
|---------|-----|--------|
| Theme | `amber.theme` | `light`, `dark` |
| Font scale | `amber.fontScale` | a double |
| Language | `amber.language` | a supported language code, such as `ro` |
| Call camera | `amber.callCamera` | `front`, `back` |
| Call audio output | `amber.callAudioOutput` | `speaker`, `earpiece` |
