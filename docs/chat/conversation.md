# Chat: Conversation state

Source: `lib/features/chat/bloc/conversation_cubit.dart`

## What it holds

`ConversationCubit` keeps one direct conversation's messages, oldest first, sorted by `seq`:

- **Load:** the newest page (20 by default). This also marks the conversation read on the server, as the backend does on the first page.
- **Older pages:** `loadOlder` fetches the page before the oldest loaded message, using its `created_at` as the `before` cursor. A short page means there is nothing older.
- **Duplicates:** the sender gets a message both in the send response and as a `message.created` event. Messages are keyed by id, so the event is ignored.

## Live updates

Events apply only when `conversation_id` matches the open conversation. Other conversations update through the contacts list.

| Event | Effect |
|---|---|
| `message.created` | Inserts the message |
| `message.edited`, `message.reacted` | Replaces the message |
| `message.deleted` | Removes it |
| `conversation.read_cursor.updated` | From the other user: marks my messages up to `last_seen_seq` as seen. My own cursor changes nothing here |

## Actions

Send text, edit, delete, and react call the API, then update local state from the response. Reacting toggles: if the current user already used that emoji, the call is a delete, otherwise an add.

`markRead()` sends the newest loaded `seq`. The screen calls it while the conversation is visible.

## Not here yet

- Replies, files and the composer send path come with the conversation view.
- Opening a conversation on the server (`openDirect`) is done by the screen before the cubit is created.
