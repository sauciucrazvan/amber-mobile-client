# 01 - Authentication

## Screens

- Login
- Register
- Verify account (from the registration email)
- Forgot password (request a code, then reset)
- Terms and Privacy (static legal text, shown from the register and login screens)

## Endpoints

| Action | Method and path |
|--------|-----------------|
| Log in | `POST /auth/v1/login` |
| Register | `POST /auth/v1/register` |
| Refresh session | `POST /auth/v1/refresh` |
| Request verification email | `POST /auth/v1/verify/request` |
| Verify account | `POST /auth/v1/verify` |
| Request password reset | `POST /account/v1/recovery/request` |
| Reset password | `POST /account/v1/recovery/reset` |

## Behavior

- Route to the main screen after login. Protect every authenticated screen so an unauthenticated user goes to login.
- An unverified account must verify before it can use the app. The desktop shows a verify notice in the sidebar and a verify dialog.
- On launch, refresh the session from secure storage. If that fails, show login.
- Sign-out clears secure storage and closes the WebSocket.

## Acceptance

- Log in, register, verify, and reset password all work against the production API.
- A bad password, an unverified account, and an expired code each show a clear message.
