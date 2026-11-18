import 'package:amber_mobile_client/app.dart';
import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('app shows the Amber home screen', (tester) async {
    final localizations = (await tester.runAsync(
      () => AppLocalizations.load('en'),
    ))!;

    await tester.pumpWidget(AmberApp(localizations: localizations));
    await tester.pumpAndSettle();

    expect(find.text('Amber'), findsOneWidget);
  });
}
