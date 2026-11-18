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
