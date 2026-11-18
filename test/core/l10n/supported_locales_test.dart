import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final code in supportedLocaleCodes) {
    test('$code translation loads and resolves a common key', () async {
      final strings = await AppLocalizations.load(code);

      expect(strings.localeCode, code);
      expect(strings.t('common.cancel'), isNot('common.cancel'));
    });
  }
}
