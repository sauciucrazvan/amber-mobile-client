import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/auth_test_app.dart';
import '../../../support/fake_http_adapter.dart';

/// Backend where the account becomes verified once `/auth/v1/verify` gets
/// [validCode]. [onRequestCode] answers `/auth/v1/verify/request`.
FakeHttpHandler _backend({
  String validCode = '123456',
  ResponseBody Function()? onRequestCode,
}) {
  var verified = false;
  return (options) {
    final path = options.path;
    if (path.endsWith('/auth/v1/login')) {
      return jsonResponse({
        'access_token': 'access-1',
        'refresh_token': 'refresh-1',
        'token_type': 'bearer',
      }, 200);
    }
    if (path.endsWith('/auth/v1/verify/request')) {
      return onRequestCode?.call() ??
          jsonResponse({'message': 'register.verify.email_sent'}, 200);
    }
    if (path.endsWith('/auth/v1/verify')) {
      final code = (options.data as Map)['verify_code'];
      if (code != validCode) {
        return jsonResponse({'detail': 'register.verify.invalid_code'}, 400);
      }
      verified = true;
      return jsonResponse({'message': 'register.verify.success'}, 200);
    }
    return jsonResponse({
      'id': 1,
      'username': 'ana',
      'full_name': 'Ana Pop',
      'verified': verified,
    }, 200);
  };
}

Future<AuthCubit> _signInUnverified(
  WidgetTester tester,
  FakeHttpHandler backend,
) async {
  final cubit = await pumpAuthApp(tester, backend);
  await tester.runAsync(() => cubit.login('ana', 'Secret123'));
  await tester.pumpAndSettle();
  return cubit;
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pump();
  await settleRequests(tester);
}

Future<void> _enterCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(EditableText).first, code);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an unverified account lands on the verify screen', (
    tester,
  ) async {
    await _signInUnverified(tester, _backend());

    expect(find.text('Verify Your Account'), findsOneWidget);
    expect(
      find.text("We'll send an email with a verification code."),
      findsOneWidget,
    );
  });

  testWidgets('send then a valid code opens the app', (tester) async {
    final cubit = await _signInUnverified(tester, _backend());

    await _tap(tester, 'Send');
    expect(
      find.textContaining('A verification email has been sent'),
      findsOneWidget,
    );

    await _enterCode(tester, '123456');
    await _tap(tester, 'Verify');

    expect(cubit.state.needsVerification, isFalse);
    expect(find.text('Ana Pop'), findsOneWidget);
  });

  testWidgets('a code sent recently goes straight to the code step', (
    tester,
  ) async {
    await _signInUnverified(
      tester,
      _backend(
        onRequestCode: () =>
            jsonResponse({'detail': 'register.verify.too_soon'}, 429),
      ),
    );

    await _tap(tester, 'Send');

    expect(
      find.text(
        'A verification email has been already sent. Retry in 30 minutes.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Please enter the code we sent to your email.'),
      findsOneWidget,
    );
  });

  testWidgets('a wrong code shows the error', (tester) async {
    await _signInUnverified(tester, _backend());

    await _tap(tester, 'Send');
    await _enterCode(tester, '000000');
    await _tap(tester, 'Verify');

    expect(find.text('The code you provided is invalid'), findsOneWidget);
  });

  testWidgets('an account verified elsewhere reloads and opens the app', (
    tester,
  ) async {
    var meCalls = 0;
    final cubit = await _signInUnverified(tester, (options) {
      final path = options.path;
      if (path.endsWith('/auth/v1/login')) {
        return jsonResponse({
          'access_token': 'access-1',
          'refresh_token': 'refresh-1',
          'token_type': 'bearer',
        }, 200);
      }
      if (path.endsWith('/auth/v1/verify/request')) {
        return jsonResponse({
          'detail': 'register.verify.already_verified',
        }, 400);
      }
      meCalls++;
      return jsonResponse({
        'id': 1,
        'username': 'ana',
        'full_name': 'Ana Pop',
        'verified': meCalls > 1,
      }, 200);
    });

    await _tap(tester, 'Send');

    expect(cubit.state.needsVerification, isFalse);
    expect(find.text('Ana Pop'), findsOneWidget);
  });
}
