# Chat: Unread counts

Sources: `lib/features/contacts/bloc/contacts_cubit.dart`, `lib/features/chat/view/conversation_screen.dart`

## How the count works

Each contact in the list shows a badge with the number of unread messages from them (`Contact.notifications`). It's loaded with the list and then kept live:

- **A new message from a contact** (`message.created` where `sender_id` is the contact) adds one to their count. Messages the current user sends are ignored, and so are messages from contacts not in the list.
- **Reading the conversation** clears the count. The chat screen calls `ContactsCubit.clearUnread` after it marks the conversation read, which happens when the chat opens and when a new message arrives while it's open.

## Why the cubit doesn't track conversation ids

The chat events identify a conversation by its id, but the contacts list is keyed by user. A message carries its sender's id, so the count can be found without a conversation-to-contact map. Clearing happens from the chat screen, which already knows both ids.

## Edge cases

- Reading a conversation on another device clears the count here only the next time that chat is opened. There is no event for a read done elsewhere. Adding one on the backend would close this gap.
- A message that arrives while the chat is open briefly increments the badge before the read clears it.
- If the screen closes before the read finishes, the clear is skipped, since the contacts cubit may already be closed.
