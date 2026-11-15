# 03 - Chat

Direct (one-to-one) conversations between contacts.

## Screens

- Conversation view: message list, composer, and the header with the contact's name and last active time
- Message bubble: text, file, and system log messages
- Image preview (full screen)
- Emoji picker
- Reactions panel (who reacted with what)

## Endpoints

| Action | Method and path |
|--------|-----------------|
| Open or create a direct conversation | `POST /chats/v1/direct/{userId}` |
| Load messages (page of 20) | `GET /chats/v1/{conversationId}/messages?limit=20` (plus a cursor for older pages) |
| Send a message or file | `POST /chats/v1/{conversationId}/messages` (multipart form: `text`, optional `file`) |
| Reply | `POST /chats/v1/{conversationId}/reply` (multipart form: `message_id`, `text` or `file`) |
| Edit text | `PATCH /chats/v1/{conversationId}/messages/{messageId}` (JSON: `text`) |
| Delete | `DELETE /chats/v1/{conversationId}/messages/{messageId}` |
| Add reaction | `POST /chats/v1/{conversationId}/messages/{messageId}/reactions` |
| Remove reaction | `DELETE /chats/v1/{conversationId}/messages/{messageId}/reactions` |
| Update read cursor | `POST /chats/v1/{conversationId}/read-cursor` |

## Realtime Events

- `message.created`, `message.edited`, `message.deleted`, `message.reacted`
- `messages.seen`
- `conversation.read_cursor.updated`

Events are only applied when `conversation_id` matches the open conversation. Other conversations update through the contact list.

## Behavior

- Show messages newest at the bottom. Load older pages when the user scrolls to the top.
- Group messages by date with a separator row.
- Reactions: the desktop offers four quick reactions (like, love, laugh, smile) plus the emoji picker.
- Send read cursors when the conversation is visible so the other side sees "seen".
- Editing and deleting are limited to the sender's own messages. Confirm before delete.

## Open Decisions

- File types and maximum size. The desktop accepts any file in the composer; confirm the backend limit before building the picker.
- Whether image previews are cached on disk.

## Acceptance

- Send text and files, reply, edit, delete, and react, with changes visible on both sides.
- Scrolling back loads older messages without losing the scroll position.
