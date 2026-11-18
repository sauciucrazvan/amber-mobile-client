# Foundation: State management and app shell

Sources: `lib/main.dart`, `lib/app.dart`, `lib/core/bloc/app_bloc_observer.dart`

## Decision

The mobile client uses **Bloc** (`flutter_bloc`) for all state, as chosen for the foundation. Feature state lives in Blocs or Cubits, and widgets read it through `BlocProvider` / `BlocBuilder`.

## What this adds

- `AmberApp` is the root widget. The Flutter counter demo is removed. The home screen is a placeholder until the auth feature replaces it.
- `AppBlocObserver` logs Bloc errors in debug builds only.

## Notes

- UI components come from the `material_ui` package, which the project already depended on.
