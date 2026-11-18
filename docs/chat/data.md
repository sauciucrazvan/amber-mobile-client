# Chat: Data layer

Sources: `lib/features/chat/data/chat_models.dart`, `lib/features/chat/data/chat_api.dart`

## Where the backend differs from the plan

The backend router (`app/api/features/chats/router.py`) is the source of truth, so the client follows it:

| Plan | Backend |
|---|---|
| `PATCH /{id}/messages/{messageId}` | `PATCH /{id}/messages` with `{text, message_id}` in the body |
| `DELETE /{id}/messages/{messageId}` | `DELETE /{id}/messages` with `{message_id}` in the body |
| `POST` / `DELETE` `/{id}/messages/{messageId}/reactions` | Same paths, `{emoji}` in the JSON body |
| `messages.seen` event | Not emitted by the backend. Read state arrives as `conversation.read_cursor.updated` |

The plan's `GET /messages?limit=20` cursor is `before`, a timestamp, not an id. Pass the oldest loaded message's `created_at`.

## Behaviour that matters for the UI

- **The first page marks the conversation read.** Calling `GET /messages` without `before` advances the read cursor on the server. Opening a chat is therefore a read, as on the desktop.
- **Read state is a seq, not a flag.** A message is seen when the other side's `last_seen_seq` is at least its `seq`. `ChatMessage.seen` already reflects this for the current user's view.
- **Replies store a snapshot.** `content.reply_to` holds the parent's id, sender, type and text at the time of reply, so the bubble doesn't need to load the parent.
- **File URLs are absolute.** They come from the server's `S3_PUBLIC_BASE_URL`, so the client loads them directly.

## Open decisions, resolved

- **File types and size.** Taken from `files.py`: 15 MB, and the content types in `ChatFileRules.allowedContentTypes`. The client checks them before uploading, so the user sees a clear message instead of a server error. The desktop accepts any file in the composer, which the backend would reject.
- **Image caching.** Images load through Flutter's in-memory image cache only. A disk cache can come later if loading is slow.

## Errors

Errors are the backend's translation keys, parsed by `ApiFailure`. Chat keys use the `conversations.error.*` namespace (for example `conversations.error.empty_message`, `conversations.error.file_too_big`).
