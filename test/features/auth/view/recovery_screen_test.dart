import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/auth_test_app.dart';
import '../../../support/fake_http_adapter.dart';

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pump();
  await settleRequests(tester);
}

Future<void> _openRecovery(WidgetTester tester) =>
    _tap(tester, 'Forgot password?');

Future<void> _requestCode(WidgetTester tester) async {
  await tester.enterText(find.byType(EditableText).first, 'ana');
  await _tap(tester, 'Next');
}

Future<void> _enterCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(EditableText).first, code);
  await tester.pumpAndSettle();
  await _tap(tester, 'Next');
}

Future<void> _enterPasswords(
  WidgetTester tester,
  String password,
  String confirmation,
) async {
  final fields = find.byType(EditableText);
  await tester.enterText(fields.at(0), password);
  await tester.enterText(fields.at(1), confirmation);
  await tester.pumpAndSettle();
  await _tap(tester, 'Finish');
}

void main() {
  testWidgets('opens from login and cancels back to it', (tester) async {
    await pumpAuthApp(tester, (_) => jsonResponse({}, 200));

    await _openRecovery(tester);
    expect(find.text('Recover your password'), findsOneWidget);

    await _tap(tester, 'Cancel');
    expect(find.text('Login into your account'), findsOneWidget);
  });

  testWidgets('resets the password and returns to login', (tester) async {
    final requests = <RequestOptions>[];
    await pumpAuthApp(tester, (options) {
      requests.add(options);
      if (options.path.endsWith('/account/v1/recovery/request')) {
        return jsonResponse({'message': 'login.recovery.sent'}, 200);
      }
      return jsonResponse({'message': 'login.recovery.success'}, 200);
    });
    await _openRecovery(tester);

    await _requestCode(tester);
    expect(
      find.textContaining('The recovery code has been sent'),
      findsOneWidget,
    );

    await _enterCode(tester, '654321');
    await _enterPasswords(tester, 'NewSecret1', 'NewSecret1');

    expect(find.text('Login into your account'), findsOneWidget);
    expect(
      find.text("You've succesfully changed your password. Please log in."),
      findsOneWidget,
    );
    expect(requests.last.path, endsWith('/account/v1/recovery/reset'));
    expect(requests.last.data, {
      'username': 'ana',
      'code': '654321',
      'new_password': 'NewSecret1',
      'new_password_confirmation': 'NewSecret1',
    });
  });

  testWidgets('catches mismatched passwords before calling the API', (
    tester,
  ) async {
    final paths = <String>[];
    await pumpAuthApp(tester, (options) {
      paths.add(options.path);
      return jsonResponse({'message': 'login.recovery.sent'}, 200);
    });
    await _openRecovery(tester);
    await _requestCode(tester);
    await _enterCode(tester, '654321');

    await _enterPasswords(tester, 'NewSecret1', 'Different1');

    expect(find.text('The passwords do not match.'), findsOneWidget);
    expect(paths.where((p) => p.endsWith('/recovery/reset')), isEmpty);
  });

  testWidgets('an invalid code returns to the code step', (tester) async {
    await pumpAuthApp(tester, (options) {
      if (options.path.endsWith('/account/v1/recovery/reset')) {
        return jsonResponse({'detail': 'login.recovery.invalid_code'}, 400);
      }
      return jsonResponse({'message': 'login.recovery.sent'}, 200);
    });
    await _openRecovery(tester);
    await _requestCode(tester);
    await _enterCode(tester, '000000');

    await _enterPasswords(tester, 'NewSecret1', 'NewSecret1');

    expect(
      find.text('The code you entered either expired or is invalid.'),
      findsOneWidget,
    );
    expect(find.text('Recovery code'), findsOneWidget);
  });
}
