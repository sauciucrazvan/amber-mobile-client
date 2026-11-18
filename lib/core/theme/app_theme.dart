import 'package:material_ui/material_ui.dart' show Brightness;
import 'package:shadcn_ui/shadcn_ui.dart';

/// Light and dark shadcn themes. The closest built-in palette to the brand
/// amber is yellow.
abstract final class AppTheme {
  static const _palette = 'yellow';

  static ShadThemeData light() =>
      ShadThemeData(colorScheme: ShadColorScheme.fromName(_palette));

  static ShadThemeData dark() => ShadThemeData(
    colorScheme: ShadColorScheme.fromName(
      _palette,
      brightness: Brightness.dark,
    ),
    brightness: Brightness.dark,
  );
}
