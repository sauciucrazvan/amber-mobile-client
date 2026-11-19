# Contacts: Profile and blocked accounts

Sources: `lib/features/contacts/view/profile_screen.dart`, `lib/features/contacts/view/blocked_accounts_screen.dart`

## Profile

Tapping a contact opens `ContactProfileScreen` (`showContactProfile`) as a full page with a back button (`AmberPage`). The layout matches the desktop's profile dialog, with text aligned to the left. It loads `GET /contacts/v1/profile/{username}` and shows:

- avatar with presence dot, display name and `@username`;
- bio, or `profile.bio.empty` when there is none;
- member since (`stats.member_since`) and last active (`stats.last_active`). Online users show `common.online`; otherwise the last active date is shown as `YYYY-MM-DD`.

Two actions, each behind a confirmation dialog with `{{user}}` filled in:

- **Remove** calls `DELETE /contacts/v1/remove` and drops the contact locally.
- **Block** calls `PUT /contacts/v1/block`. The contact and any pending request are removed locally, as in `ContactsCubit.block`.

After either action the profile closes and a toast confirms it. Cancelling the dialog sends nothing.

The profile route is outside the home screen's provider, so the `ContactsCubit` is passed in with `BlocProvider.value`.

## Blocked accounts

The ban button in the home header opens `BlockedAccountsScreen`. It lists `GET /contacts/v1/blocked` with an **Unblock** button per user, which calls `DELETE /contacts/v1/unblock`.

Unblocking sends no realtime event, so the screen reloads its list after each unblock. The desktop keeps this under Settings → Account; it moves there with feature 06.

## Not in this step

- Opening a profile from a chat header is part of feature 03.
- Profile editing belongs to the Account feature (06).
- Dates use a plain `YYYY-MM-DD` format, not a localized one. Localizing them needs `intl`, which isn't a dependency yet.
