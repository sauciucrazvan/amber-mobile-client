# Contacts: Data and live state

Sources: `lib/features/contacts/data/`, `lib/features/contacts/bloc/contacts_cubit.dart`

## Endpoints

Taken from the backend router (`app/api/features/contacts/router.py`), which differs from the plan in three places, marked below.

| Action | Request |
|---|---|
| List contacts | `GET /contacts/v1/list` |
| List incoming requests | `GET /contacts/v1/requests` |
| List blocked | `GET /contacts/v1/blocked` |
| Profile | `GET /contacts/v1/profile/{username}` (plan: by id) |
| Send request | `POST /contacts/v1/request` `{identifier}` (username or email) |
| Accept / decline | `POST /contacts/v1/accept` / `decline` `{username}` |
| Remove | `DELETE /contacts/v1/remove` `{username}` |
| Block | `PUT /contacts/v1/block` `{username}` (plan: POST) |
| Unblock | `DELETE /contacts/v1/unblock` `{username}` (plan: POST) |

Errors are translation keys, parsed by `ApiFailure` (moved from auth to `core/network`). Many contact messages use a `{{user}}` placeholder, so screens pass the username: `l10n.t(key, params: {'user': username})`.

## Live state

`ContactsCubit` loads both lists once, then applies realtime events instead of refetching:

| Event | Effect |
|---|---|
| `contact.request.received` | Adds the request (deduplicated by user id) |
| `contact.request.removed` | Removes the request |
| `contact.accepted` | Adds or replaces the contact and clears its request |
| `contact.removed` | Removes the contact matching `user_id` or `other_user_id` (one of them is the current user) |
| `contact.profile.updated` | Updates name, avatar, online and last active |
| `contact.last_action.updated` | Updates the last action and re-sorts |
| `contact.last_message.updated` | Sets or clears the last message preview |
| `presence` `user_connected` / `user_disconnected` | Toggles online. Going offline sets last active to now |

Accept, decline, remove and block also update the lists locally once the API call succeeds, so they work even when the WebSocket is down. Blocking removes both the contact and any pending request, matching the backend and the desktop.

The list is sorted by last action, newest first, then by username, as the backend does.

## Not here

Unseen-message counts come from `GET /contacts/v1/list` (`notifications`). Keeping them live depends on chat events, so that belongs to the chat feature (03).

## Foundation change

`RealtimeClient.events` exposes every incoming event, for features such as contacts that handle several event names.
