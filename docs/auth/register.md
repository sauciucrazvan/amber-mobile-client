# Auth: Register and legal texts

Sources: `lib/features/auth/view/register_screen.dart`, `lib/features/auth/view/legal_dialog.dart`, `lib/features/auth/view/signed_out_flow.dart`

## Behaviour

- Reached from the login screen's "Register" link. `SignedOutFlow` swaps the screens in place, so nothing stays on the navigator stack after the user signs in.
- Fields: username, display name, email, password. The backend requires all four, so empty fields show `register.fillInput` without calling the API.
- On submit, `AuthCubit.register` posts to `/auth/v1/register`, then logs in with the same credentials. The new account is unverified, so the verify step follows.
- Backend validation errors (`422`, `detail.errors`) appear under their fields: `register.invalidUsername`, `register.usernameTaken`, `register.invalidPassword`, `register.nameRequired`, `register.invalidName`, `register.emailRequired`, `register.invalidEmail`, `register.emailTaken`.
- Hints (`register.usernameHint`, `register.emailHint`, `register.passwordHint`) show under a field until it has an error.

## Legal texts

- `register.terms` contains `<terms>…</terms>` and `<privacy>…</privacy>` tags. Each becomes a tappable link.
- `showLegalDialog` opens the matching `legal.terms` or `legal.privacy` text in a `ShadDialog`.
- The shared locale files store line breaks in the legal content as a literal `\n`, which the dialog converts to real line breaks.

## Layout

`AuthSwitchPrompt` holds the "Already have an account? Login" style prompts. It wraps instead of overflowing on narrow screens and large font scales.
