import 'package:amber_mobile_client/features/chat/view/conversation_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/auth_test_app.dart';
import '../../../support/fake_http_adapter.dart';

/// Bob has two unread messages in the contact list.
const _bobContact = {
  'user': {
    'id': 2,
    'username': 'bob',
    'full_name': 'Bob Ionescu',
    'avatar_url': null,
    'online': true,
    'last_active_at': null,
  },
  'created_at': '2026-11-01T00:00:00+00:00',
  'last_action_at': '2026-11-18T00:00:00+00:00',
  'notifications': 2,
  'last_message': null,
};

Map<String, Object?> _message(String id, int seq) => {
  'id': id,
  'conversation_id': 'c-1',
  'sender_id': 2,
  'seq': seq,
  'type': 'text',
  'content': {'text': 'message $seq'},
  'reaction_details': [],
  'created_at': '2026-11-18T1$seq:00:00+00:00',
  'edited_at': null,
  'seen': false,
};

FakeHttpHandler _backend() {
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
    if (path.endsWith('/contacts/v1/list')) {
      return jsonResponse([_bobContact], 200);
    }
    if (path.endsWith('/contacts/v1/requests')) return jsonResponse([], 200);
    if (path.endsWith('/chats/v1/direct/2')) {
      return jsonResponse({
        'id': 'c-1',
        'type': 'direct',
        'created_at': '2026-11-01T00:00:00+00:00',
        'notifications': 2,
      }, 200);
    }
    if (path.contains('/chats/v1/c-1/messages') && options.method == 'GET') {
      return jsonResponse([_message('m-1', 1), _message('m-2', 2)], 200);
    }
    if (path.endsWith('/read-cursor')) {
      return jsonResponse({
        'conversation_id': 'c-1',
        'reader_id': 1,
        'last_seen_seq': 2,
        'updated': 2,
      }, 200);
    }
    return jsonResponse({'message': 'ok'}, 200);
  };
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('reading a chat clears its unread badge', (tester) async {
    final cubit = await pumpAuthApp(tester, _backend());
    await tester.runAsync(() => cubit.login('ana', 'Secret123'));
    await settleRequests(tester);

    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('Bob Ionescu'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.byType(ConversationScreen), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsNothing);
  });
}
