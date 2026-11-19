import 'package:amber_mobile_client/features/calls/view/call_history_tab.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/auth_test_app.dart';
import '../../../support/fake_http_adapter.dart';

Map<String, Object?> _call({
  required String id,
  required String status,
  required String? reason,
  required int duration,
  required int peerId,
  required String name,
}) => {
  'call_id': id,
  'status': status,
  'call_mode': 'video',
  'started_at': '2026-11-18T10:00:00+00:00',
  'ended_at': '2026-11-18T10:01:05+00:00',
  'duration_seconds': duration,
  'end_reason': reason,
  'peer': {
    'id': peerId,
    'username': name.toLowerCase().split(' ').first,
    'display_name': name,
    'avatar_url': null,
    'last_active_at': null,
  },
};

FakeHttpHandler _backend(List<Map<String, Object?>> calls) {
  return (options) {
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
    if (path.contains('/calls/v1/history')) {
      return jsonResponse({
        'total': calls.length,
        'limit': 50,
        'offset': 0,
        'calls': calls,
      }, 200);
    }
    return jsonResponse({'message': 'ok'}, 200);
  };
}

Future<void> _openCalls(WidgetTester tester, FakeHttpHandler backend) async {
  final cubit = await pumpAuthApp(tester, backend);
  await tester.runAsync(() => cubit.login('ana', 'Secret123'));
  await settleRequests(tester);
  await tester.tap(find.byKey(const ValueKey('nav-calls')));
  await settleRequests(tester);
}

void main() {
  testWidgets('recent calls show the peer, the reason and the length', (
    tester,
  ) async {
    await _openCalls(
      tester,
      _backend([
        _call(
          id: 'c1',
          status: 'ended',
          reason: 'ended',
          duration: 65,
          peerId: 2,
          name: 'Bob Ionescu',
        ),
        _call(
          id: 'c2',
          status: 'missed',
          reason: 'missed',
          duration: 0,
          peerId: 3,
          name: 'Carol Marin',
        ),
      ]),
    );

    expect(find.text('Bob Ionescu'), findsOneWidget);
    expect(find.text('Ended'), findsOneWidget);
    expect(find.text('01:05'), findsOneWidget);
    expect(find.text('Carol Marin'), findsOneWidget);
    expect(find.text('Missed'), findsOneWidget);
  });

  testWidgets('an account with no calls sees the empty message', (
    tester,
  ) async {
    await _openCalls(tester, _backend([]));

    expect(find.byType(CallHistoryTab), findsOneWidget);
    expect(find.text('No calls yet'), findsOneWidget);
  });

  test('the duration reads as minutes and seconds', () {
    expect(formatCallDuration(0), '00:00');
    expect(formatCallDuration(65), '01:05');
    expect(formatCallDuration(3600), '60:00');
  });
}
