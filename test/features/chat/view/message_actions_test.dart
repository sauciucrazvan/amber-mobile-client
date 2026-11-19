import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

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

/// A text message. `seq` also sets the created time, keeping the list ordered.
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

/// A file message from Bob, to check the file-only actions.
Map<String, Object?> _fileMessage(String id, int seq, int sender) => {
  'id': id,
  'conversation_id': 'c-1',
  'sender_id': sender,
  'seq': seq,
  'type': 'file',
  'content': {
    'url': 'https://files.example/notes.txt',
    'filename': 'notes.txt',
    'content_type': 'text/plain',
    'size': 12,
  },
  'reaction_details': [],
  'created_at': '2026-11-18T1$seq:00:00+00:00',
  'edited_at': null,
  'seen': false,
};

/// Records every chat request so the tests can check the calls made.
FakeHttpHandler _backend(List<RequestOptions> calls) {
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
      return jsonResponse([
        _message('m-1', 1, 2, 'hello there'),
        _message('m-2', 2, 1, 'hi Bob'),
        _fileMessage('m-4', 3, 2),
      ], 200);
    }
    if (path.endsWith('/reply')) {
      return jsonResponse(_message('m-3', 3, 1, 'agreed'), 200);
    }
    if (path.endsWith('/chats/v1/c-1/messages') && options.method == 'DELETE') {
      return jsonResponse({'message': 'ok'}, 200);
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

Future<void> _openChat(WidgetTester tester, List<RequestOptions> calls) async {
  final cubit = await pumpAuthApp(tester, _backend(calls));
  await tester.runAsync(() => cubit.login('ana', 'Secret123'));
  await settleRequests(tester);
  await _tap(tester, find.text('Bob Ionescu'));
}

void main() {
  testWidgets('replying from a long press sends a reply to that message', (
    tester,
  ) async {
    final calls = <RequestOptions>[];
    await _openChat(tester, calls);

    await tester.longPress(find.text('hello there'));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Reply'));

    expect(find.text('Reply: hello there'), findsOneWidget);

    await tester.enterText(find.byType(EditableText).last, 'agreed');
    await _tap(tester, find.byKey(const ValueKey('send-message')));

    final reply = calls.lastWhere((c) => c.path.endsWith('/reply'));
    final fields = Map.fromEntries((reply.data as FormData).fields);
    expect(fields['message_id'], 'm-1');
    expect(fields['text'], 'agreed');
  });

  testWidgets('Save as is offered on file messages only', (tester) async {
    final calls = <RequestOptions>[];
    await _openChat(tester, calls);

    await tester.longPress(find.text('hello there'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('save-as')), findsNothing);
    await tester.tapAt(const Offset(1, 1));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('notes.txt'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('save-as')), findsOneWidget);
  });

  testWidgets('deleting asks first, then sends the delete', (tester) async {
    final calls = <RequestOptions>[];
    await _openChat(tester, calls);

    await tester.longPress(find.text('hi Bob'));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('Delete'));

    expect(find.byType(ShadDialog), findsOneWidget);
    expect(calls.where((c) => c.method == 'DELETE'), isEmpty);

    await _tap(
      tester,
      find.descendant(
        of: find.byType(ShadDialog),
        matching: find.text('Delete'),
      ),
    );

    final delete = calls.lastWhere((c) => c.method == 'DELETE');
    expect(delete.data, {'message_id': 'm-2'});
    expect(find.text('hi Bob'), findsNothing);
  });

  testWidgets('a message from someone else has no edit or delete', (
    tester,
  ) async {
    final calls = <RequestOptions>[];
    await _openChat(tester, calls);

    await tester.longPress(find.text('hello there'));
    await tester.pumpAndSettle();

    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
    expect(find.text('Edit'), findsNothing);
  });
}
