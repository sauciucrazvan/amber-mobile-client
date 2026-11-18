# Auth: Account verification

Sources: `lib/features/auth/view/verify_account_screen.dart`, `lib/features/auth/view/widgets/code_input.dart`, `lib/features/auth/bloc/auth_cubit.dart`

## Behaviour

- `AuthGate` shows `VerifyAccountScreen` instead of the app while the signed-in account is unverified (`AuthState.needsVerification`). An unverified user cannot use the app, as the plan requires.
- Step one: "Send" calls `POST /auth/v1/verify/request`. The backend emails a six-digit code.
- Step two: the user enters the code in `CodeInput`, and "Verify" calls `POST /auth/v1/verify` with `verify_code`.
- On success, `AuthCubit.verify` reloads `/account/v1/me`. The account is now verified, so the gate opens the app. The backend's `account.updated` WebSocket push updates the same flag, but the reload doesn't depend on it.
- "Back" returns to step one. A sign-out link lets the user leave the account.

## Errors

| Key | When | Screen |
|---|---|---|
| `register.verify.too_soon` | A code was sent in the last 30 minutes | Shows the message and moves to the code step, since the earlier code is still valid |
| `register.verify.already_verified` | The account was verified elsewhere | Reloads the account, and the gate opens the app |
| `register.verify.invalid_code` | Wrong or malformed code | Shows the message |
| `login.recovery.too_late` | The code expired (30 minutes) | Shows the message |
| `register.verify.locked` | Too many wrong codes | Shows the message |

## Code input

`CodeInput` wraps `ShadInputOTP` with six digit-only slots, in two groups of three. Password recovery uses it too.
