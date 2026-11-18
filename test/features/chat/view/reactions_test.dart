import 'package:flutter/widgets.dart';
import 'package:dio/dio.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// Bob's message with a thumbs-up from Bob and from me. [mine] is whether
/// the reaction list includes my id.
Map<String, Object?> _bobMessage({required bool reactedByMe}) => {
  'id': 'm-1',
  'conversation_id': 'c-1',
  'sender_id': 2,
  'seq': 1,
  'type': 'text',
  'content': {'text': 'hello there'},
  'reaction_details': [
    {
      'emoji': '👍',
      'count': reactedByMe ? 2 : 1,
      'user_ids': reactedByMe ? [2, 1] : [2],
      'first_added_at': '2026-11-18T10:00:00+00:00',
    },
  ],
  'created_at': '2026-11-18T10:00:00+00:00',
  'edited_at': null,
  'seen': false,
};

FakeHttpHandler _backend(
  List<RequestOptions> calls, {
  bool reactedByMe = false,
}) {
  return (options) {
    calls.add(options);
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
        'notifications': 0,
      }, 200);
    }
    if (path.contains('/chats/v1/c-1/messages') && options.method == 'GET') {
      return jsonResponse([_bobMessage(reactedByMe: reactedByMe)], 200);
    }
    if (path.contains('/reactions')) {
      return jsonResponse(
        _bobMessage(reactedByMe: options.method == 'POST'),
        200,
      );
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

Future<void> _openChat(
  WidgetTester tester,
  List<RequestOptions> calls, {
  bool reactedByMe = false,
}) async {
  final cubit = await pumpAuthApp(
    tester,
    _backend(calls, reactedByMe: reactedByMe),
  );
  await tester.runAsync(() => cubit.login('ana', 'Secret123'));
  await settleRequests(tester);
  await _tap(tester, find.text('Bob Ionescu'));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('tapping a reaction shows who reacted', (tester) async {
    final calls = <RequestOptions>[];
    await _openChat(tester, calls);

    await _tap(tester, find.byKey(const ValueKey('reactions-m-1')));

    expect(find.text('Bob Ionescu'), findsWidgets);
    expect(find.text('Click to react'), findsOneWidget);
  });

  testWidgets('removing my own reaction sends a delete', (tester) async {
    final calls = <RequestOptions>[];
    await _openChat(tester, calls, reactedByMe: true);

    await _tap(tester, find.byKey(const ValueKey('reactions-m-1')));
    await _tap(tester, find.text('Remove your reaction'));

    final remove = calls.lastWhere((c) => c.method == 'DELETE');
    expect(remove.path, endsWith('/messages/m-1/reactions'));
    expect(remove.data, {'emoji': '👍'});
  });

  testWidgets('More reactions opens the full emoji picker', (tester) async {
    final calls = <RequestOptions>[];
    await _openChat(tester, calls);

    await tester.longPress(find.text('hello there'));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('more-reactions')));

    expect(find.byType(EmojiPicker), findsOneWidget);
  });
}
