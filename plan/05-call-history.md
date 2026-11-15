# 05 - Call History

A list of recent calls, shown as a tab in the main navigation.

## Screens

- Call history list: contact, direction (incoming, outgoing, missed), mode (audio or video), time, and duration
- Tapping an entry opens the contact's chat or starts a new call

## Endpoints

| Action | Method and path |
|--------|-----------------|
| List history | `GET /calls/v1/history?limit={n}&offset={n}` |

The desktop loads one page with a fixed limit and offset 0. Mobile should add paging with offset as the user scrolls.

## Behavior

- Refresh the list after a call ends so the new entry appears.
- Missed calls come from the backend history. Confirm whether the backend marks them, or whether the client has to derive them.

## Acceptance

- The list matches the desktop for the same account.
- A call that just ended appears without restarting the app.
