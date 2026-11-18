import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Font scales offered by the desktop client (0.8x to 2x).
const List<double> fontScaleOptions = [0.8, 0.9, 1.0, 1.2, 1.5, 2.0];

class AppearanceState {
  const AppearanceState({
    this.themeMode = ThemeMode.dark,
    this.fontScale = 1.0,
  });

  final ThemeMode themeMode;
  final double fontScale;

  AppearanceState copyWith({ThemeMode? themeMode, double? fontScale}) {
    return AppearanceState(
      themeMode: themeMode ?? this.themeMode,
      fontScale: fontScale ?? this.fontScale,
    );
  }
}

/// Holds the theme and font scale, and saves them per device.
class AppearanceCubit extends Cubit<AppearanceState> {
  AppearanceCubit() : super(const AppearanceState());

  static const _themeKey = 'amber.theme';
  static const _fontScaleKey = 'amber.fontScale';

  /// Loads the saved values. Unknown stored values fall back to the defaults.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeMode = prefs.getString(_themeKey) == 'light'
        ? ThemeMode.light
        : ThemeMode.dark;
    final fontScale = prefs.getDouble(_fontScaleKey);

    emit(
      AppearanceState(
        themeMode: themeMode,
        fontScale: fontScaleOptions.contains(fontScale) ? fontScale! : 1.0,
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    assert(mode != ThemeMode.system, 'Mobile offers only light and dark.');

    emit(state.copyWith(themeMode: mode));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themeKey,
      mode == ThemeMode.light ? 'light' : 'dark',
    );
  }

  Future<void> setFontScale(double scale) async {
    assert(fontScaleOptions.contains(scale), 'Unsupported font scale.');

    emit(state.copyWith(fontScale: scale));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, scale);
  }
}
