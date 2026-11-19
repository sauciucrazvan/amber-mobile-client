import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../support/auth_test_app.dart';
import '../../../support/fake_http_adapter.dart';

/// [requestMessage] is what the request step answers: confirm_sent when the
/// current email needs a code first, verify_sent when it does not.
FakeHttpHandler _backend(
  List<RequestOptions> log, {
  required String requestMessage,
}) {
  return (options) {
    log.add(options);
    final path = options.path;
    if (path.endsWith('/auth/v1/login')) {
      return jsonResponse({
        'access_token': 'access-1',
        'refresh_token': 'refresh-1',
        'token_type': 'bearer',
      }, 200);
    }
    if (path.endsWith('/account/v1/me')) {
      return jsonResponse({
        'id': 1,
        'username': 'ana',
        'full_name': 'Ana Pop',
        'verified': true,
      }, 200);
    }
    if (path.endsWith('/contacts/v1/list')) return jsonResponse([], 200);
    if (path.endsWith('/contacts/v1/requests')) return jsonResponse([], 200);
    if (path.endsWith('/modify/email/request')) {
      return jsonResponse({'message': requestMessage}, 200);
    }
    if (path.endsWith('/modify/email/confirm')) {
      return jsonResponse({
        'message': 'settings.account.email.verify_sent',
      }, 200);
    }
    if (path.endsWith('/modify/email/verify')) {
      return jsonResponse({'message': 'settings.account.email.updated'}, 200);
    }
    if (path.contains('/calls/v1/history')) {
      return jsonResponse({
        'total': 0,
        'limit': 50,
        'offset': 0,
        'calls': [],
      }, 200);
    }
    return jsonResponse({'message': 'ok'}, 200);
  };
}

Future<void> _openEmailDialog(
  WidgetTester tester,
  List<RequestOptions> log,
  String message,
) async {
  final cubit = await pumpAuthApp(
    tester,
    _backend(log, requestMessage: message),
  );
  await tester.runAsync(() => cubit.login('ana', 'Secret123'));
  await settleRequests(tester);
  await tester.tap(find.byKey(const ValueKey('nav-settings')));
  await settleRequests(tester);
  await tester.ensureVisible(find.byKey(const ValueKey('account-email')));
  await tester.tap(find.byKey(const ValueKey('account-email')));
  await settleRequests(tester);
}

Future<void> _fill(WidgetTester tester, Finder field, String text) async {
  await tester.enterText(field, text);
  await tester.pump();
}

void main() {
  testWidgets(
    'the email change asks for the current email code, then the new one',
    (tester) async {
      final log = <RequestOptions>[];
      await _openEmailDialog(
        tester,
        log,
        'settings.account.email.confirm_sent',
      );

      await _fill(
        tester,
        find.byKey(const ValueKey('email-new')),
        'ana@new.example',
      );
      await _fill(
        tester,
        find.byKey(const ValueKey('email-password')),
        'Secret123',
      );
      await tester.tap(find.byKey(const ValueKey('email-continue')));
      await settleRequests(tester);

      expect(
        log.lastWhere((r) => r.path.endsWith('/modify/email/request')).data,
        {'new_email': 'ana@new.example', 'password': 'Secret123'},
      );

      await _fill(tester, find.byKey(const ValueKey('email-code')), '111111');
      await tester.tap(find.byKey(const ValueKey('email-continue')));
      await settleRequests(tester);
      expect(
        log.lastWhere((r) => r.path.endsWith('/modify/email/confirm')).data,
        {'code': '111111'},
      );

      await _fill(tester, find.byKey(const ValueKey('email-code')), '222222');
      await tester.tap(find.byKey(const ValueKey('email-continue')));
      await settleRequests(tester);
      expect(
        log.lastWhere((r) => r.path.endsWith('/modify/email/verify')).data,
        {'code': '222222'},
      );
      expect(find.byType(ShadDialog), findsNothing);
    },
  );

  testWidgets(
    'when the code goes straight to the new email, the confirm step is skipped',
    (tester) async {
      final log = <RequestOptions>[];
      await _openEmailDialog(tester, log, 'settings.account.email.verify_sent');

      await _fill(
        tester,
        find.byKey(const ValueKey('email-new')),
        'ana@new.example',
      );
      await _fill(
        tester,
        find.byKey(const ValueKey('email-password')),
        'Secret123',
      );
      await tester.tap(find.byKey(const ValueKey('email-continue')));
      await settleRequests(tester);

      expect(log.any((r) => r.path.endsWith('/modify/email/confirm')), isFalse);
      expect(
        find.text('Enter the verification code sent to: ana@new.example'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('email-code')), findsOneWidget);
    },
  );
}
