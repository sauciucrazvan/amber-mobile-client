import 'package:material_ui/material_ui.dart';

/// Light and dark themes. The seed colour is the brand amber.
abstract final class AppTheme {
  static const _seed = Colors.amber;

  static ThemeData light() => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );

  static ThemeData dark() => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
}
