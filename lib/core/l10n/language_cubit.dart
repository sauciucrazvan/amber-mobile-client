import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Each language, named in itself, for the language chooser.
const languageNames = {
  'en': 'English',
  'ro': 'Română',
  'de': 'Deutsch',
  'fr': 'Français',
  'es': 'Español',
  'zh': '中文',
  'ja': '日本語',
  'it': 'Italiano',
};

/// Holds the strings the app shows. Changing the language reloads them, so
/// the whole app switches at once.
class LanguageCubit extends Cubit<AppLocalizations> {
  LanguageCubit(super.initial);

  static const _key = 'amber.language';

  /// Loads the language to start with: the one the user chose, if any,
  /// otherwise the device's first supported language.
  static Future<AppLocalizations> loadStartup(
    Iterable<String> deviceTags,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    final code = saved != null && supportedLocaleCodes.contains(saved)
        ? saved
        : resolveLocaleCode(deviceTags);
    return AppLocalizations.load(code);
  }

  Future<void> setLanguage(String code) async {
    if (code == state.localeCode) return;
    final localizations = await AppLocalizations.load(code);
    emit(localizations);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}
