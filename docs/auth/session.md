# Auth: Session and auth gate

Sources: `lib/features/auth/`, `lib/main.dart`, `lib/app.dart`

## Pieces

- `AuthApi` calls `/auth/v1/*` and `/account/v1/recovery/*`. Every error becomes an `ApiFailure`.
- `ApiFailure.messageKey` is a translation key. The backend sends keys such as `login.incorrectCredentials` in `detail`, so screens show `l10n.t(failure.messageKey)`. Register also fills `fieldErrors` (`username`, `password`, `full_name`, `email`).
- `AuthCubit` owns the session: launch restore, login, register, sign-out, and the realtime connection.
- `AuthGate` is the app's home. It shows a screen for each `AuthStatus`, so a signed-out user never reaches an authenticated screen.
- `main.dart` is the composition root. It builds the session store, API client, realtime client and auth cubit.

## Error shapes

| Backend response | `ApiFailure` |
|---|---|
| `{"detail": "login.incorrectCredentials"}` | `messageKey` = the detail |
| `{"detail": {"errors": [{"field", "error"}]}}` (register, 422) | `fieldErrors`, plus the first error as `messageKey` |
| `{"detail": [...]}` (FastAPI validation, missing form fields) | `login.fillInput` |
| No `detail` with status 429 (rate limiter) | `common.errors.too_many_requests` |
| No response (offline) | `common.connection.failed` |

## Launch

1. `start()` refreshes the session from the stored refresh token.
2. Success loads `/account/v1/me`, emits `authenticated`, and connects realtime.
3. No stored token, or a token the server rejects, emits `unauthenticated` and shows login.
4. A network error emits `unreachable`. The refresh token is kept, and the gate shows a retry button. This differs from the plan's "show login" on purpose: an offline launch should not sign the user out.

## Sign-out and expiry

- `signOut()` disconnects realtime and clears the tokens through `ApiClient.signOut()`, which does not fire `onSessionExpired`.
- A session the server rejects mid-use triggers `onSessionExpired`, which disconnects realtime and returns to login.

## Verification

- `AuthState.needsVerification` is true when the account's `verified` flag is false.
- The backend pushes `account.updated` over the WebSocket after a successful verify, with `verified` inside `payload`. The cubit applies it, and `refreshAccount()` reloads `/me` as a fallback.

## Known gaps

- There is no shared translation key for "Retry", so the button text is English.
- The backend can send `login.recovery.invalid_email`, which is missing from the shared locale files. It shows as the raw key until the key is added to both clients.
