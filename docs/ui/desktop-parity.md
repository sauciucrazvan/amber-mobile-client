# UI: Desktop parity fixes

These fix the items marked "built, but differs from the desktop". Features the desktop has and mobile doesn't yet (calls, call history, settings, account editing) are not part of this change.

## What changed

- **Reply quotes scroll to the original.** Tapping a quote scrolls to that message when it's loaded. A message that isn't loaded yet can't be scrolled to. The desktop loads it, which is a gap.
- **Files open on tap.** Tapping a non-image file opens its URL, which downloads it. The image preview has a download button. Both use `url_launcher`.
- **Connection feedback.** A thin progress bar shows while the live connection is being set up. When it fails, one error toast appears, as on the desktop.
- **Shared strings.** "Retry" is now a translation key (`common.retry`). `login.recovery.invalid_email` is added to the English file. Other languages fall back to English.

## Still different

- Read state from other devices (backend gap).
- Edit history, multiple files in one send, and the desktop's file save-as dialog.
- Settings-based language choice.

## Navigation and presence

- The home screen has a bottom bar with Chats and Inbox, built from shadcn buttons since `shadcn_ui` has no bottom bar. Calls, call history and settings will be added here.
- The add-contact button floats over the bottom-right of the contacts, as on the desktop sidebar.
- Contact avatars show a green dot when online and a red dot when offline, as on the desktop.
- Dialogs use `AmberDialog`: rounded corners (8px) and left-aligned title and text.
- Profiles open as full pages (`AmberPage`) with a back button, using the same layout as the desktop's profile dialog.
- The Chats tab uses the `messageCircle` icon, as on the desktop.
- The theme keeps the desktop's neutral palette, so buttons stay neutral. The logo's orange (`AppColors.brand`, `#FF9831`) is used only for the round add-contact button, with white text.
- Profile pages are centred on the screen, and sign-out is pinned to the bottom (`AmberPage.footer`).
- The Chats header has no logo.
