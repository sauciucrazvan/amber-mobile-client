# Foundation: Theme and font scale

Sources: `lib/core/theme/app_theme.dart`, `lib/core/theme/appearance_cubit.dart`, `lib/app.dart`

## What it does

- Light and dark `ShadThemeData` from `shadcn_ui`, the UI library AGENTS.md requires. `ShadApp.custom` provides them. `MaterialApp` stays underneath only as the navigator root.
- `AppearanceCubit` holds the theme mode and the font scale. `AmberApp` rebuilds from it, so changes apply right away with no restart.
- The font scale is applied as a `TextScaler` through `MediaQuery`, so it scales all text in the app.
- Values are saved per device with `shared_preferences` (keys `amber.theme` and `amber.fontScale`). Unknown stored values fall back to the defaults.

## Defaults and options

- Theme defaults to **dark**, matching the desktop client.
- Mobile offers only **light** and **dark**. `ThemeMode.system` is rejected by an assertion.
- Font scales are `0.8`, `0.9`, `1.0`, `1.2`, `1.5`, `2.0`, the same presets as the desktop.

## Notes

- The Settings screen that changes these values is part of feature 07 (`plan/07-settings.md`). This step provides the state and persistence only.
- shadcn has no amber palette. `AppTheme` uses the built-in `yellow` scheme as the closest match. Swap it for a custom `ShadColorScheme` when the brand colour is chosen.
