import 'package:amber_mobile_client/core/theme/appearance_cubit.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to dark theme and 1.0x font scale', () async {
    final cubit = AppearanceCubit();
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.themeMode, ThemeMode.dark);
    expect(cubit.state.fontScale, 1.0);
  });

  test('saves and reloads the theme and font scale', () async {
    final cubit = AppearanceCubit();
    addTearDown(cubit.close);

    await cubit.setThemeMode(ThemeMode.light);
    await cubit.setFontScale(1.5);

    final reloaded = AppearanceCubit();
    addTearDown(reloaded.close);
    await reloaded.load();

    expect(reloaded.state.themeMode, ThemeMode.light);
    expect(reloaded.state.fontScale, 1.5);
  });

  test('falls back to defaults for unsupported stored values', () async {
    SharedPreferences.setMockInitialValues({
      'amber.theme': 'purple',
      'amber.fontScale': 3.0,
    });
    final cubit = AppearanceCubit();
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.themeMode, ThemeMode.dark);
    expect(cubit.state.fontScale, 1.0);
  });
}
