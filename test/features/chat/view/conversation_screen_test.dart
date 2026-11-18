import 'package:amber_mobile_client/features/chat/view/message_bubble.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../support/auth_test_app.dart';
import '../../../support/fake_http_adapter.dart';

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
  'notifications': 0,
  'last_message': null,
};

Map<String, Object?> _message(String id, int seq, int sender, String text) => {
  'id': id,
  'conversation_id': 'c-1',
  'sender_id': sender,
  'seq': seq,
  'type': 'text',
  'content': {'text': text},
  'reaction_details': [],
  'created_at': '2026-11-18T1$seq:00:00+00:00',
  'edited_at': null,
  'seen': false,
};

/// Backend for a signed-in user with one contact and an existing chat.
FakeHttpHandler _backend({List<String> sent = const []}) {
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
        'direct_pair': 'pair',
        'created_at': '2026-11-01T00:00:00+00:00',
        'notifications': 0,
      }, 200);
    }
    if (path.contains('/chats/v1/c-1/messages') && options.method == 'GET') {
      return jsonResponse([
        _message('m-1', 1, 2, 'hello there'),
        _message('m-2', 2, 1, 'hi Bob'),
      ], 200);
    }
    if (path.endsWith('/chats/v1/c-1/messages') && options.method == 'POST') {
      final text = (options.data as FormData).fields.first.value;
      sent.add(text);
      return jsonResponse(_message('m-3', 3, 1, text), 200);
    }
    if (path.endsWith('/read-cursor')) {
      return jsonResponse({
        'conversation_id': 'c-1',
        'reader_id': 1,
        'last_seen_seq': 2,
        'updated': 0,
      }, 200);
    }
    return jsonResponse({'message': 'ok'}, 200);
  };
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opening a contact shows the chat history', (tester) async {
    final cubit = await pumpAuthApp(tester, _backend());
    await tester.runAsync(() => cubit.login('ana', 'Secret123'));
    await settleRequests(tester);

    await _tap(tester, find.text('Bob Ionescu'));

    expect(find.text('hello there'), findsOneWidget);
    expect(find.text('hi Bob'), findsOneWidget);
    expect(find.byType(DaySeparator), findsOneWidget);
    expect(find.byType(MessageBubble), findsNWidgets(2));
  });

  testWidgets('sending a message adds it to the chat', (tester) async {
    final sent = <String>[];
    final cubit = await pumpAuthApp(tester, _backend(sent: sent));
    await tester.runAsync(() => cubit.login('ana', 'Secret123'));
    await settleRequests(tester);
    await _tap(tester, find.text('Bob Ionescu'));

    await tester.enterText(find.byType(EditableText).last, 'on my way');
    await _tap(tester, find.byKey(const ValueKey('send-message')));

    expect(sent, ['on my way']);
    expect(find.text('on my way'), findsOneWidget);
    expect(find.byType(EditableText).last, findsOneWidget);
  });
}
