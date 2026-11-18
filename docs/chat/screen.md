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

## Message actions

Long-pressing a message opens a sheet (`showMessageActions`):

- **Quick reactions:** 👍 ❤️ 😂 😊, sent through `ConversationCubit.react`. Reacting again with the same emoji removes it.
- **Reply:** a banner above the composer shows the message being replied to. Sending calls `POST /reply`, and the reply shows a quote of the parent.
- **Edit** (own text messages only): the composer loads the text and sends a `PATCH`. An `edited` label shows on the bubble.
- **Delete** (own messages only): asks for confirmation first, then calls `DELETE`. The message is removed locally.

Cancelling the banner clears the reply or edit target.

## Not in this step

- File uploads, image preview and the full emoji picker are later steps. The sheet has the four quick reactions only.
- Dates use `YYYY-MM-DD` for now, because localized dates need `intl`.
