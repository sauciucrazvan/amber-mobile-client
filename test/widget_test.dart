import 'package:amber_mobile_client/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('app shows the Amber home screen', (tester) async {
    await tester.pumpWidget(const AmberApp());
    await tester.pumpAndSettle();

    expect(find.text('Amber'), findsOneWidget);
  });
}
