import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/home/home_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/auth_test_app.dart';
import '../../../support/fake_http_adapter.dart';

Future<void> _fillAndSubmit(
  WidgetTester tester, {
  String username = 'ana',
  String password = 'Secret123',
}) async {
  await tester.enterText(find.byType(EditableText).at(0), username);
  await tester.enterText(find.byType(EditableText).at(1), password);
  await tester.tap(find.text('Login'));
  await tester.pump();
}

void main() {
  testWidgets('asks for input when fields are empty', (tester) async {
    await pumpAuthApp(tester, (_) => jsonResponse({}, 200));

    await tester.tap(find.text('Login'));
    await tester.pump();

    expect(find.text('Fill in the input fields'), findsOneWidget);
  });

  testWidgets('shows the translated backend error', (tester) async {
    await pumpAuthApp(tester, (options) {
      if (options.path.endsWith('/auth/v1/login')) {
        return jsonResponse({'detail': 'login.incorrectCredentials'}, 401);
      }
      return jsonResponse({}, 200);
    });

    await _fillAndSubmit(tester, password: 'wrong');
    await settleRequests(tester);

    expect(
      find.text('Incorrect username/email and/or password.'),
      findsOneWidget,
    );
  });

  testWidgets('a successful login opens the signed-in screen', (tester) async {
    final cubit = await pumpAuthApp(tester, (options) {
      if (options.path.endsWith('/auth/v1/login')) {
        return jsonResponse({
          'access_token': 'access-1',
          'refresh_token': 'refresh-1',
          'token_type': 'bearer',
        }, 200);
      }
      return jsonResponse({
        'id': 1,
        'username': 'ana',
        'full_name': 'Ana Pop',
        'verified': true,
      }, 200);
    });

    await _fillAndSubmit(tester);
    await settleRequests(tester);

    expect(cubit.state.status, AuthStatus.authenticated);
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
