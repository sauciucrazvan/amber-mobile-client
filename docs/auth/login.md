# Auth: Login

Sources: `lib/features/auth/view/login_screen.dart`, `lib/features/auth/view/widgets/auth_form_layout.dart`

## Behaviour

- Shown by `AuthGate` whenever the user is signed out.
- Username (or email) and password fields, built from `shadcn_ui` inputs with autofill hints.
- Empty fields show `login.fillInput` without calling the API.
- On submit, `AuthCubit.login` posts to `/auth/v1/login`. On success the gate switches to the signed-in screen.
- Backend errors are shown through `l10n.t(failure.messageKey)`. Examples: `login.incorrectCredentials` (401), `login.account_disabled` (410), `login.locked` (429 after repeated failures).

## Shared layout

`AuthFormLayout` (title, subtitle, form) and `AuthErrorAlert` are reused by the register and recovery screens.

## Not in this step

- The "Forgot password?" and "Register" links are added with their screens.
- The desktop shows a "Welcome back" toast after login. Mobile skips it for now, since the gate switches screens immediately.
