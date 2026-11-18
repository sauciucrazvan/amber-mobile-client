# Foundation: Session storage

Sources: `lib/core/session/key_value_storage.dart`, `lib/core/session/session_store.dart`

## What it does

- Stores the **refresh token** in platform secure storage: Keychain on iOS, Keystore on Android.
- Stores a **WebSocket session id**: a UUID generated once per install and reused, as `plan/00-foundation.md` requires.
- The access token is not persisted. It is kept in memory and obtained again from the refresh token.

## Layers

- `KeyValueStorage` is a minimal string store. `SecureKeyValueStorage` implements it with `flutter_secure_storage`.
- `SessionStore` owns the keys (`amber.refreshToken`, `amber.wsSessionId`) and takes any `KeyValueStorage`, so tests use an in-memory fake.

## Clearing the session

Sign-out and refresh failure call `clearRefreshToken()`. The session id is kept on purpose, so the realtime session identity stays stable.

## Notes

- Keychain entries can survive an app uninstall on iOS, so the session id may outlive a reinstall there, even though the plan describes it as "once per install".
