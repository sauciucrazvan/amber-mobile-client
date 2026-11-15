# 00 - Foundation

Shared infrastructure every other feature depends on.

## API Client

- Base URL `https://api.amber.albertgalan.ro/api`, with the path appended to it.
- Authenticated requests attach the access token. On an expired token, call `/auth/v1/refresh` once and retry.
- The desktop builds URLs with a helper (`apiUrl`) and allows the base URL to be replaced at runtime. Mobile should keep the base URL in one config object.

## Realtime (WebSocket)

- Connect to `wss://api.amber.albertgalan.ro/ws` with `token` and `session_id` query parameters. `session_id` is a UUID generated once per install and reused.
- Send a heartbeat to `/ping` so the connection stays alive.
- Reconnect with backoff. Expose connection state to the UI (connecting, connected, failed, disconnected). The desktop shows a thin progress bar at the top and one error toast when a connection fails.
- Route incoming events by their `event` name to the feature that owns them (see the feature files).

## Session Storage

- Store the refresh token in platform secure storage (Keychain on iOS, Keystore on Android). The desktop uses a token storage module in `src/features/auth/tokenStorage.ts`.
- Clear the session on sign-out and on a refresh failure.

## Server Config

- Default to the production server. The desktop lets a developer switch servers in About. Mobile can skip this in the first version and read the base URLs from a build flavor instead.

## Localization

- The desktop ships 8 locales: en, de, es, fr, it, ja, ro, zh. Mobile should use the same keys so translations can be shared.
- The locale files are in `src/locales/*.json` on the desktop. Mobile can use Flutter's `intl` / ARB tooling and reuse the strings.

## Theme

- Light and dark themes, plus a font scale setting (see [07-settings.md](07-settings.md)).

## Open Decisions

- State management: pick one (for example Riverpod or Bloc) and use it everywhere.
- HTTP and WebSocket packages.
- Minimum supported OS versions for iOS and Android.
