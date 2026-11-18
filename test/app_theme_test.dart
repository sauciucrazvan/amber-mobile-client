import 'package:amber_mobile_client/app.dart';
import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Material surfaces follow the shadcn theme mode', (tester) async {
    SharedPreferences.setMockInitialValues({'amber.theme': 'dark'});
    final localizations = (await tester.runAsync(
      () => AppLocalizations.load('en'),
    ))!;

    await tester.pumpWidget(AmberApp(localizations: localizations));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
