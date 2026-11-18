# Foundation: App config

Source: `lib/core/config/app_config.dart`

## What it does

Holds the backend endpoints in one place and builds API URLs from them.

- `AppConfig.apiBaseUrl` defaults to `https://api.amber.albertgalan.ro/api`.
- `AppConfig.wsBaseUrl` defaults to `wss://api.amber.albertgalan.ro/ws`.
- `AppConfig.apiUrl(path)` appends a path to the API base. Absolute `http(s)` URLs pass through unchanged.

## Overriding the server

Values come from compile-time defines, so no runtime server switcher is needed on mobile:

```sh
flutter run --dart-define=AMBER_API_BASE_URL=http://localhost/api --dart-define=AMBER_WS_BASE_URL=ws://localhost/ws
```

## Notes

- The desktop client uses `api.amber.razvansauciuc.dev`. The plan's backend is `api.amber.albertgalan.ro`, and mobile follows the plan.
