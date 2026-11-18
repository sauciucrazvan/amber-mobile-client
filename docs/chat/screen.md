# Chat: Conversation screen

Sources: `lib/features/chat/view/conversation_screen.dart`, `lib/features/chat/view/message_bubble.dart`

## Opening a chat

Tapping a contact on the home screen opens the conversation. This replaces the earlier profile tap. The profile is reached from the chat header.

`ConversationScreen` calls `POST /chats/v1/direct/{userId}` to get the conversation, then starts a `ConversationCubit`, which loads the newest page. The first page marks the conversation read on the server.

## Layout

- **Header:** the contact's name and their status (`common.online`, or the last active date). Tapping the header opens the profile.
- **Messages:** newest at the bottom. Scrolling up loads older pages before the list reaches the top. A spinner shows while a page loads.
- **Day dividers:** each day's first message gets a divider above it, labelled `YYYY-MM-DD`.
- **Bubbles:** the current user's messages align right in the primary colour, others align left. Each bubble shows the time, `edited` when edited, and `seen` on the current user's messages once the other side has read them.
- **Log messages** (system entries such as call logs) show in italics.
- **Composer:** a text field (`conversations.type_message`) and a send button. Sending clears the field after success. A failed send shows a toast.

## Read state

Each time a new newest message arrives, the screen calls `markRead()`, which sends the newest loaded `seq`.

## Not in this step

- File, reply, edit, delete and reaction actions come in the next step.
- Image preview, the emoji picker and file uploads are later steps.
- Dates use `YYYY-MM-DD` for now, because localized dates need `intl`.
