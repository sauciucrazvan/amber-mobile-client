import 'package:flutter_test/flutter_test.dart';

import 'support/auth_test_app.dart';
import 'support/fake_http_adapter.dart';

void main() {
  testWidgets('a signed-out user lands on login', (tester) async {
    await pumpAuthApp(tester, (_) => jsonResponse({}, 200));

    expect(find.text('Login into your account'), findsOneWidget);
  });
}
