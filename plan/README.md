# Amber Mobile Client - Feature Plan

This plan maps the features of the [desktop client](https://github.com/sauciucrazvan/amber-desktop-client) that the mobile client should mirror. It covers only the core functionality. Each feature gets its own file here and its own feature branch and PR.

## Scope

Included (core):

1. [Foundation](00-foundation.md): API client, WebSocket, token storage, server config, i18n, theme
2. [Authentication](01-auth.md): login, register, email verification, password recovery
3. [Contacts](02-contacts.md): contact list, requests, blocking, presence
4. [Chat](03-chat.md): direct conversations, messages, reactions, read state
5. [Calls](04-calls.md): audio and video calls over WebRTC
6. [Call history](05-call-history.md): recent calls list
7. [Account](06-account.md): profile, avatar, email and password changes, privacy, data export, account deletion
8. [Settings](07-settings.md): devices, appearance, about

Excluded (desktop-only, see [08-desktop-only.md](08-desktop-only.md)): system tray, start on boot, auto-updater, custom titlebar, window controls, sidebar placement.

## Ground Rules

- One feature per branch (`feature/<name>`) and one PR per feature. Keep each PR under 1.5k lines.
- Each feature adds a doc under `docs/` when it is implemented.
- Conventional commit messages.
- The API and WebSocket contracts are the same backend the desktop uses (`api.amber.albertgalan.ro`). Mobile must not change them.

## Suggested Order

Dependencies run top to bottom: foundation first, then auth, then contacts (chat needs contacts), chat, calls (calls are started from chat and contacts), call history, account, and settings.

## Feature Map

| # | Feature | Desktop source | Backend surface |
|---|---------|----------------|-----------------|
| 00 | Foundation | `src/config.ts`, `src/features/auth/`, `src/i18n.ts`, `src/components/theme/` | `/ping`, `/ws` |
| 01 | Auth | `src/views/auth/`, `src/features/auth/` | `/auth/v1/*`, `/account/v1/recovery/*` |
| 02 | Contacts | `src/components/common/app-sidebar/`, `src/views/dialogs/AddContact.tsx`, `UserProfile.tsx` | `/contacts/v1/*` |
| 03 | Chat | `src/features/chat/` | `/chats/v1/*` |
| 04 | Calls | `src/features/calls/` | `/ws` (`call.*`, `webrtc.*`) |
| 05 | Call history | `app-sidebar/components/CallHistoryTab.tsx` | `/calls/v1/history` |
| 06 | Account | `src/views/settings/tabs/account/`, `src/views/dialogs/MyProfile.tsx` | `/account/v1/*` |
| 07 | Settings | `src/views/settings/tabs/` | local only |
