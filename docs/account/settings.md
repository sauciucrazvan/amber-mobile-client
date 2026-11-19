# Account: Editing settings

Sources: `lib/features/account/`, `lib/features/settings/view/settings_screen.dart`

The Account section of the Settings tab edits the signed-in user's details.

| Row | Saves with | Notes |
|-----|-----------|-------|
| Name | `PATCH /account/v1/modify/fullname` | The server allows one change a week. A refused change shows the server's message. |
| Bio | `PATCH /account/v1/modify/bio` | Up to 256 characters, checked before sending. |
| Password | `PATCH /account/v1/modify/password` | Checks that the new password and its confirmation match. On success the app signs out, because the server rotates the session. |
| Let people find you | `PATCH /account/v1/settings/privacy` | Switch for `allow_add_by_email`. A setting the server does not send counts as on. |

| Change email | `POST /account/v1/modify/email/request`, then `/confirm` (only when the server asks for the current email's code), then `/verify` | A three-step dialog. The request takes the new email and the password. The server's answer decides whether the confirm step shows. The change is final at the verify step. |
| Avatar | `POST /account/v1/upload/avatar` (multipart field `file`) | Picks a JPEG, PNG or WebP image up to 5 MB, checked before upload, then asks for confirmation. The server returns the new address, and the account refreshes. |
| Request your data | `POST /account/v1/request/data` | The server sends the copy by email, and allows one request a week. |
| Delete account | `DELETE /account/v1/delete` (JSON: `password`) | Asks for the password, then confirms once more. On success the app clears the session and returns to sign-in. Device settings such as theme and language stay. |

Each save refreshes the account, so the new value shows at once. Errors show the server's translation key as a toast.

With the email change, the account section covers everything in plan 06 except the signed-in profile and sign-out, which were already in place.
