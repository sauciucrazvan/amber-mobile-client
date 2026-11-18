import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Colours the desktop uses outside the shadcn scheme.
abstract final class AppColors {
  /// Presence dot for an online contact (`bg-emerald-500`).
  static const online = Color(0xFF10B981);

  /// Presence dot for an offline contact (`bg-red-500`).
  static const offline = Color(0xFFEF4444);
}

/// Light and dark themes that match the desktop client.
///
/// The desktop uses shadcn's neutral palette (`globals.css`, converted from
/// oklch to sRGB), an 8px control radius, and control heights of 32, 36 and
/// 40px. Disabled controls use 50% opacity.
abstract final class AppTheme {
  static ShadThemeData light() => ShadThemeData(
    brightness: Brightness.light,
    colorScheme: _lightScheme,
    radius: _radius,
    disabledOpacity: 0.5,
    buttonSizesTheme: _buttonSizes,
  );

  static ShadThemeData dark() => ShadThemeData(
    brightness: Brightness.dark,
    colorScheme: _darkScheme,
    radius: _radius,
    disabledOpacity: 0.5,
    buttonSizesTheme: _buttonSizes,
  );

  static final _radius = BorderRadius.circular(8);

  static final _buttonSizes = ShadButtonSizesTheme(
    regular: ShadButtonSizeTheme(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    sm: ShadButtonSizeTheme(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),
    lg: ShadButtonSizeTheme(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    ),
    icon: ShadButtonSizeTheme(height: 36, width: 36, padding: EdgeInsets.zero),
  );

  static const _lightScheme = ShadColorScheme(
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF0A0A0A),
    card: Color(0xFFFFFFFF),
    cardForeground: Color(0xFF0A0A0A),
    popover: Color(0xFFFFFFFF),
    popoverForeground: Color(0xFF0A0A0A),
    primary: Color(0xFF171717),
    primaryForeground: Color(0xFFFAFAFA),
    secondary: Color(0xFFF5F5F5),
    secondaryForeground: Color(0xFF171717),
    muted: Color(0xFFF5F5F5),
    mutedForeground: Color(0xFF737373),
    accent: Color(0xFFF5F5F5),
    accentForeground: Color(0xFF171717),
    destructive: Color(0xFFE7000B),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFFE5E5E5),
    input: Color(0xFFE5E5E5),
    ring: Color(0xFFA1A1A1),
    selection: Color(0x33171717),
  );

  static const _darkScheme = ShadColorScheme(
    background: Color(0xFF0A0A0A),
    foreground: Color(0xFFFAFAFA),
    card: Color(0xFF171717),
    cardForeground: Color(0xFFFAFAFA),
    popover: Color(0xFF171717),
    popoverForeground: Color(0xFFFAFAFA),
    primary: Color(0xFFE5E5E5),
    primaryForeground: Color(0xFF171717),
    secondary: Color(0xFF262626),
    secondaryForeground: Color(0xFFFAFAFA),
    muted: Color(0xFF262626),
    mutedForeground: Color(0xFFA1A1A1),
    accent: Color(0xFF262626),
    accentForeground: Color(0xFFFAFAFA),
    destructive: Color(0xFFFF6467),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0x1AFFFFFF),
    input: Color(0x26FFFFFF),
    ring: Color(0xFF737373),
    selection: Color(0x33E5E5E5),
  );
}
