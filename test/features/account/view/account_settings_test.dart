import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../support/auth_test_app.dart';
import '../../../support/fake_http_adapter.dart';

FakeHttpHandler _backend(List<RequestOptions> log) {
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
        'bio': null,
        'verified': true,
        'privacy_settings': {'allow_add_by_email': true},
      }, 200);
    }
    if (path.endsWith('/contacts/v1/list')) return jsonResponse([], 200);
    if (path.endsWith('/contacts/v1/requests')) return jsonResponse([], 200);
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

Future<void> _openSettings(
  WidgetTester tester,
  List<RequestOptions> log,
) async {
  final cubit = await pumpAuthApp(tester, _backend(log));
  await tester.runAsync(() => cubit.login('ana', 'Secret123'));
  await settleRequests(tester);
  await tester.tap(find.byKey(const ValueKey('nav-settings')));
  await settleRequests(tester);
}

void main() {
  testWidgets('changing the name saves it on the server', (tester) async {
    final log = <RequestOptions>[];
    await _openSettings(tester, log);

    await tester.ensureVisible(find.byKey(const ValueKey('account-name')));
    await tester.tap(find.byKey(const ValueKey('account-name')));
    await settleRequests(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(ShadDialog),
        matching: find.byType(EditableText),
      ),
      'Ana Maria Pop',
    );
    await tester.tap(
      find.descendant(
        of: find.byType(ShadDialog),
        matching: find.text('Change'),
      ),
    );
    await settleRequests(tester);

    final patch = log.lastWhere((r) => r.method == 'PATCH');
    expect(patch.path, endsWith('/account/v1/modify/fullname'));
    expect(patch.data, {'new_full_name': 'Ana Maria Pop'});
  });

  testWidgets('the privacy switch saves the setting', (tester) async {
    final log = <RequestOptions>[];
    await _openSettings(tester, log);

    await tester.ensureVisible(
      find.byKey(const ValueKey('privacy-add-by-email')),
    );
    await tester.tap(find.byKey(const ValueKey('privacy-add-by-email')));
    await settleRequests(tester);

    final patch = log.lastWhere((r) => r.method == 'PATCH');
    expect(patch.path, endsWith('/account/v1/settings/privacy'));
    expect(patch.data, {'setting': 'allow_add_by_email', 'value': false});
  });
}
