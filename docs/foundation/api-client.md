# Foundation: API client

Sources: `lib/core/network/api_client.dart`

## What it does

- Builds URLs with `AppConfig.apiUrl`, so every request uses the configured base URL.
- Attaches `Authorization: Bearer <access token>` to requests made with a token.
- On a `401` from an authenticated request, calls `POST /auth/v1/refresh` once and retries the request.
- Concurrent `401`s share a single refresh call.
- On app start, `restoreSession()` exchanges the stored refresh token for an access token.

## Session rules

- A refresh rejected by the server (any HTTP response) clears the refresh token and calls `onSessionExpired`.
- A network error during refresh keeps the session. The request fails, and the user stays signed in.
- Requests with no access token (login, register) never trigger a refresh. A wrong password cannot clear a stored session.

## Usage

```dart
final client = ApiClient(sessionStore: sessionStore, onSessionExpired: onExpired);
await client.saveTokens(TokenPair.fromJson(loginJson));
final response = await client.request<Map<String, dynamic>>('/users/me');
```

## Notes

- The desktop client logs out on any failed refresh, including offline errors. Mobile keeps the session on network errors on purpose.
- `accessToken` is exposed read-only so the realtime client can read the current token.
