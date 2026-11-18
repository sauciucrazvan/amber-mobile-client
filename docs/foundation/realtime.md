# Foundation: Realtime (WebSocket)

Sources: `lib/core/realtime/realtime_client.dart`

## What it does

- Opens `wss://…/ws/ping?token=…&session_id=…` and sends `ping` on open and every 30 seconds.
- Reconnects with exponential backoff: 1s, 2s, 4s, … capped at 30s. The backoff resets after a successful connect.
- A close with code `1008` (token rejected) refreshes the access token once, then reconnects. If the refresh is rejected, the client stops.
- Exposes connection state as `RealtimeConnectionState`: `connecting`, `connected`, `failed`, `disconnected`. The UI can listen on `states`.
- Routes incoming JSON messages by their `event` field: `client.on('user_connected')` returns only those events.

## Usage

```dart
final realtime = RealtimeClient(
  sessionId: sessionId,
  readAccessToken: () async => accessToken,
  refreshAccessToken: apiClient.refresh,
);
await realtime.connect();
realtime.on('user_connected').listen(handlePresence);
```

## Notes

- The plan says to connect to `…/ws` and send a heartbeat to `/ping`. The desktop client connects to `…/ws/ping` and sends a text `ping`, so mobile matches the desktop.
- The UI progress bar and error toast from the desktop are UI work and belong to the feature screens, not this layer.
