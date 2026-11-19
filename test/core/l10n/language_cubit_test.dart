import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/l10n/language_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('choosing a language reloads the strings and saves the choice', (
    tester,
  ) async {
    final english = (await tester.runAsync(() => AppLocalizations.load('en')))!;
    final cubit = LanguageCubit(english);
    addTearDown(cubit.close);

    await tester.runAsync(() => cubit.setLanguage('ro'));

    expect(cubit.state.localeCode, 'ro');
    expect(cubit.state.t('contacts.title'), 'Chaturi');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('amber.language'), 'ro');
  });

  testWidgets('startup uses the saved language over the device language', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'amber.language': 'de'});

    final localizations = (await tester.runAsync(
      () => LanguageCubit.loadStartup(['fr-FR']),
    ))!;

    expect(localizations.localeCode, 'de');
  });

  testWidgets('startup falls back to the device language when none is saved', (
    tester,
  ) async {
    final localizations = (await tester.runAsync(
      () => LanguageCubit.loadStartup(['fr-FR', 'en-US']),
    ))!;

    expect(localizations.localeCode, 'fr');
  });
}
