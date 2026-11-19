# Chat: File uploads

Sources: `lib/features/chat/data/chat_file_rules.dart`, `lib/features/chat/view/conversation_screen.dart`, `lib/features/chat/view/message_bubble.dart`, `lib/features/chat/view/image_preview.dart`

## Sending a file

The paperclip in the composer opens the system file picker, limited to the accepted extensions. The chosen file is checked on the device before anything uploads:

1. **Type:** the extension must be in `ChatFileRules.contentTypes`. The content type sent to the backend comes from the same table, since the backend rejects files without an accepted type.
2. **Size:** at most 15 MB, the backend's `FILE_MAX_SIZE_BYTES`. Empty files are rejected too.

A failed check shows a toast with the matching message and nothing is uploaded. A passed check sends the file with any text in the composer as its caption, via `POST /messages` (or `POST /reply` when replying).

Attachments are disabled while editing, because an edit changes only the text.

## Showing a file

- **Images** (`image/*`) show a preview in the bubble. Tapping opens `ImagePreviewScreen`, a full-screen view you can pinch to zoom. A failed load falls back to the file row.
- **Other files** show an icon, the file name and the size (`512 B`, `240 KB` or `3.2 MB`). Tapping opens the file in the browser.
- **Save as:** long-press a file message and choose Save as. The file downloads, then the system save dialog asks where to keep it. Cancelling the dialog saves nothing, and a failed download shows `conversations.files.save_failed`.
- A caption, if any, appears below the attachment.

Images load through Flutter's in-memory image cache. A disk cache is a later step.

## Not in this step

- Sending several files at once. The picker allows one file per send.
- Showing a file's type or dimensions.

## Translation keys

The backend's upload messages (`conversations.error.file_too_big` and `file_type_not_accepted`) aren't in the shared locale files, so the app checks the same rules itself and uses its own keys, `conversations.files.too_big`, `type_not_accepted` and `empty`. These exist in `en.json` only, and other languages fall back to English. The desktop client should get the same keys.
