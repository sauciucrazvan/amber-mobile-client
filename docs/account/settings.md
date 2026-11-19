# Account: Editing settings

Sources: `lib/features/account/`, `lib/features/settings/view/settings_screen.dart`

The Account section of the Settings tab edits the signed-in user's details.

| Row | Saves with | Notes |
|-----|-----------|-------|
| Name | `PATCH /account/v1/modify/fullname` | The server allows one change a week. A refused change shows the server's message. |
| Bio | `PATCH /account/v1/modify/bio` | Up to 256 characters, checked before sending. |
| Password | `PATCH /account/v1/modify/password` | Checks that the new password and its confirmation match. On success the app signs out, because the server rotates the session. |
| Let people find you | `PATCH /account/v1/settings/privacy` | Switch for `allow_add_by_email`. A setting the server does not send counts as on. |

Each save refreshes the account, so the new value shows at once. Errors show the server's translation key as a toast.

Still to come: email change (three steps), avatar, data export, and account deletion.
