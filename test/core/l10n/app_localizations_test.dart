import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolveLocaleCode', () {
    test('uses the first supported language', () {
      expect(resolveLocaleCode(['de-AT', 'en-US']), 'de');
      expect(resolveLocaleCode(['pt-BR', 'ro']), 'ro');
    });

    test('falls back to English when nothing is supported', () {
      expect(resolveLocaleCode(['xx-YY']), 'en');
      expect(resolveLocaleCode([]), 'en');
    });
  });

  group('AppLocalizations', () {
    test('looks up dotted keys', () async {
      final strings = await AppLocalizations.load('en');

      expect(strings.localeCode, 'en');
      expect(strings.t('common.cancel'), 'Cancel');
    });

    test('returns the key when it does not exist', () async {
      final strings = await AppLocalizations.load('en');

      expect(strings.t('does.not.exist'), 'does.not.exist');
    });

    test('replaces {{name}} placeholders with params', () async {
      final strings = await AppLocalizations.load('en');

      expect(
        strings.t('calls.history.relative.minutesAgo', params: {'count': 5}),
        '5m ago',
      );
    });

    test('keeps a placeholder that has no matching param', () async {
      final strings = await AppLocalizations.load('en');

      expect(strings.t('calls.history.relative.minutesAgo'), '{{count}}m ago');
    });
  });
}
