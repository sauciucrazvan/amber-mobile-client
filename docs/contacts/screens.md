# Contacts: Home, list, inbox and add contact

Sources: `lib/features/home/home_screen.dart`, `lib/features/contacts/view/`

## Home

`AuthGate` shows `HomeScreen` once the user is signed in and verified. It creates the `ContactsCubit` from `AppServices` (API client and realtime events) and loads it.

- Header: the current tab's title and your avatar (opens your profile). Sign-out lives in the profile.
- Bottom bar, left to right: **Inbox** (requests, with a badge for the pending count), **Chats** (the default), and **Settings**. Blocked accounts are in Settings.
- The add-contact button floats in the bottom-right corner of the Chats tab, round and in the primary colour.
- The tab bodies sit in an `IndexedStack`, so each list keeps its scroll position.

## Contacts list

- One row per contact, most recent activity first.
- `ContactAvatar`: the avatar image, falling back to initials, with a green presence dot while the contact is online.
- Subtitle: the last message preview, or Online / Offline when there is none.
- `lastMessagePreview` matches the desktop: text content, file name or `contacts.last_message.attachment`, call logs from `calls.logs.*` (falling back to `contacts.last_message.call`), and `contacts.last_message.unknown` for other types. Messages the user sent get a "You: " prefix (`conversations.you`).
- A badge shows the unseen-message count from the list response.
- Loading, failed (with a retry) and empty (`contacts.none`) states.
- No pull-to-refresh: realtime events keep the list current, and AGENTS.md limits UI components to shadcn.

## Inbox

Each request shows the avatar, name and `@username`, with Decline and Accept buttons. The result is shown in a toast (`contacts.accepted`, `contacts.declined`, or the backend error), with `{{user}}` filled in.

## Add contact

An `AmberDialog` (a `ShadDialog` with rounded corners and left-aligned text) with one field (`contacts.add.identifier`, username or email). Success closes the dialog and toasts `contacts.requested`. Errors such as `contacts.invalid_user`, `contacts.already_added` or `contacts.blocked.unreachable` stay in the dialog.

## App changes

- `AppServices` (API client and realtime events) is provided at the app root, so signed-in features can build their APIs.
- The app shell wraps the navigator in a `ShadToaster`. `ShadApp.custom` does not add one, so toasts would otherwise fail.
- `AuthGate` pops any pushed screens when the user leaves the signed-in state.

## Not yet

Tapping a contact does nothing yet. The profile screen comes in the next step, and the chat with feature 03.

## Contacts search

The Chats tab has a search box above the list (`contacts.search_placeholder`). It filters by display name or username, ignoring case. A leading `@` is ignored, so `@bob` finds `bob`. When nothing matches, the list shows `contacts.no_results`.
