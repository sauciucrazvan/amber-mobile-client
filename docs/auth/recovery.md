# Auth: Password recovery

Sources: `lib/features/auth/view/recovery_screen.dart`, `lib/features/auth/view/signed_out_flow.dart`

## Behaviour

Opened from the login screen's "Forgot password?" link. Three steps, as in the desktop dialog:

1. **Username.** "Next" calls `POST /account/v1/recovery/request` with `{username}`. The backend emails a six-digit code.
2. **Code.** The user enters the code in `CodeInput`. The code is not checked here. The backend checks it in the last step.
3. **New password.** "Finish" calls `POST /account/v1/recovery/reset` with `username`, `code`, `new_password` and `new_password_confirmation`. On success the screen returns to login, which shows `login.recovery.success`.

"Back" returns to the previous step. "Cancel" on the first step returns to login.

## Errors

| Key | Screen |
|---|---|
| `login.recovery.different_passwords` | Checked on the device before calling the API, and also returned by the backend |
| `login.recovery.too_soon` | A code was requested in the last 30 minutes. Moves to the code step |
| `login.recovery.invalid_code` | Returns to the code step |
| `login.recovery.too_late` | The code expired. Returns to the username step to request a new one |
| `login.recovery.invalid_username`, `login.recovery.invalid_password`, `register.invalidPassword`, `login.recovery.locked`, `login.account_disabled` | Shows the message on the current step |

## Known gap

The backend can return `login.recovery.invalid_email`, which is missing from the shared locale files. It shows as the raw key until the key is added to both clients.
