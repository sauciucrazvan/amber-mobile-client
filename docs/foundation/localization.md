# Foundation: Localization

Sources: `lib/core/l10n/app_localizations.dart`, `assets/locales/*.json`

## Approach

Translations are the desktop client's JSON files, copied into `assets/locales/`. The keys are the same, so a translation fixed on one client applies to the other. Flutter's ARB/`gen-l10n` tooling was not used, because it requires flat, identifier-safe keys and would break that key sharing.

## What it does

- `AppLocalizations.load(code)` reads `assets/locales/<code>.json` and always loads English as the fallback.
- `t('common.cancel')` looks up a dotted key. `t('…', params: {'count': 5})` replaces `{{count}}`.
- A missing key falls back to English. A key missing in English returns the key itself, so gaps are visible on screen.
- `AppLocalizationsScope` makes the instance available to the widget tree. `AppLocalizations.of(context)` reads it.
- At startup `main` picks the first supported language from the device's preferred locales and falls back to English.

## Supported locales

`en`, `ro`, `de`, `fr`, `es`, `zh`, `ja`, `it`, the same eight as the desktop.

## Notes

- The language is taken from the device for now. A language picker belongs to the Settings feature (07).
- Some keys differ between locales. The desktop files each lack two keys compared with English, and `zh` has one extra key. The fallback covers the missing ones.
