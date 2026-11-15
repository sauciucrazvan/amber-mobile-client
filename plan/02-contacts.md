# 02 - Contacts

## Screens

- Contacts list (with unseen-message counts and last message preview)
- Requests list (incoming requests with accept and decline)
- Add contact (by user identifier)
- User profile (avatar, name, bio, member since, last active, block and remove actions)
- Blocked accounts (list and unblock)

## Endpoints

| Action | Method and path |
|--------|-----------------|
| List contacts | `GET /contacts/v1/list` |
| List requests | `GET /contacts/v1/requests` |
| Send a request | `POST /contacts/v1/request` |
| Accept or decline | `POST /contacts/v1/accept` or `POST /contacts/v1/decline` |
| Remove contact | `DELETE /contacts/v1/remove` |
| Block | `POST /contacts/v1/block` |
| Unblock | `POST /contacts/v1/unblock` |
| List blocked | `GET /contacts/v1/blocked` |
| User profile | `GET /contacts/v1/profile/{id}` |

## Realtime Events

- `contact.request.received`, `contact.request.removed`, `contact.accepted`, `contact.removed`
- `contact.profile.updated`
- `contact.last_action.updated` (presence and last active)
- `contact.last_message.updated`

Presence comes from `user_connected` and `user_disconnected` events.

## Behavior

- Keep the list live by applying these events to local state. Do not refetch the whole list on each event.
- Blocking a contact also removes them from the list, matching the desktop.

## Acceptance

- Send, accept, decline, remove, block, and unblock all update the list without a manual refresh.
- Presence dots and last-active text update in real time.
