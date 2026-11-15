# 06 - Account

Managing your own profile and account. The desktop puts most of this in Settings > Account and in the My Profile dialog.

## Screens

- My profile: avatar, name, bio, member since
- Account settings: edit name, change email, change password, avatar, privacy settings
- Manage account data: request a data export
- Delete account (with confirmation)
- Sign out (with confirmation)

## Endpoints

| Action | Method and path |
|--------|-----------------|
| Current user | `GET /account/v1/me` |
| Update name | `PATCH /account/v1/modify/fullname` |
| Update bio | `PATCH /account/v1/modify/bio` |
| Upload avatar | `POST /account/v1/upload/avatar` (multipart, jpeg, png, or webp) |
| Privacy settings | `PATCH /account/v1/settings/privacy` |
| Change password | `PATCH /account/v1/modify/password` (JSON: `current_password`, `new_password`, `new_password_confirmation`) |
| Change email (request, confirm, verify) | `POST /account/v1/modify/email/request`, then `/confirm`, then `/verify` |
| Request data export | `POST /account/v1/request/data` |
| Delete account | `DELETE /account/v1/delete` |

## Behavior

- Email change is a three-step flow. The desktop walks through each step in a dialog. Mobile should do the same.
- Changing the password should keep the user signed in or send them to login. Confirm the backend behavior.
- Deleting the account is irreversible. Require the password and a separate confirmation step.
- Avatar: check the file type and size before uploading. The desktop accepts jpeg, png, and webp.

## Acceptance

- Each field saves and the profile shows the new value.
- The email change works end to end, including the verification code.
- Account deletion signs the user out and clears local data.
