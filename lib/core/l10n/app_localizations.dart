import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:material_ui/material_ui.dart';

const supportedLocaleCodes = ['en', 'ro', 'de', 'fr', 'es', 'zh', 'ja', 'it'];
const fallbackLocaleCode = 'en';

/// Picks the first supported language from [preferredTags], such as
/// `['de-AT', 'en-US']`. Falls back to English.
String resolveLocaleCode(Iterable<String> preferredTags) {
  for (final tag in preferredTags) {
    final language = tag.toLowerCase().split(RegExp('[-_]')).first;
    if (supportedLocaleCodes.contains(language)) return language;
  }
  return fallbackLocaleCode;
}

/// Translated strings for one locale, loaded from `assets/locales/<code>.json`.
///
/// Keys are dotted paths into the JSON, such as `common.cancel`. Values may
/// contain `{{name}}` placeholders. Keys missing in the locale fall back to English.
class AppLocalizations {
  const AppLocalizations._(this.localeCode, this._strings, this._fallback);

  final String localeCode;
  final Map<String, dynamic> _strings;
  final Map<String, dynamic> _fallback;

  static Future<AppLocalizations> load(String localeCode) async {
    final fallback = await _loadJson(fallbackLocaleCode);
    final strings = localeCode == fallbackLocaleCode
        ? fallback
        : await _loadJson(localeCode);
    return AppLocalizations._(localeCode, strings, fallback);
  }

  static Future<Map<String, dynamic>> _loadJson(String code) async {
    final raw = await rootBundle.loadString('assets/locales/$code.json');
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static AppLocalizations of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLocalizationsScope>();
    assert(scope != null, 'No AppLocalizationsScope above this context.');
    return scope!.localizations;
  }

  /// Returns the string for [key], replacing `{{name}}` with [params].
  String t(String key, {Map<String, Object?> params = const {}}) {
    final template = _lookup(_strings, key) ?? _lookup(_fallback, key) ?? key;

    return template.replaceAllMapped(RegExp(r'\{\{(\w+)\}\}'), (match) {
      final name = match.group(1)!;
      return '${params[name] ?? match.group(0)}';
    });
  }

  static String? _lookup(Map<String, dynamic> root, String key) {
    Object? node = root;
    for (final part in key.split('.')) {
      if (node is! Map<String, dynamic>) return null;
      node = node[part];
    }
    return node is String ? node : null;
  }
}

/// Makes [AppLocalizations] available to the widget tree.
class AppLocalizationsScope extends InheritedWidget {
  const AppLocalizationsScope({
    super.key,
    required this.localizations,
    required super.child,
  });

  final AppLocalizations localizations;

  @override
  bool updateShouldNotify(AppLocalizationsScope oldWidget) =>
      localizations.localeCode != oldWidget.localizations.localeCode;
}
