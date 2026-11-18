import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:amber_mobile_client/core/session/session_store.dart';
import 'package:amber_mobile_client/features/chat/data/chat_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/memory_key_value_storage.dart';

const _textMessage = {
  'id': 'm-1',
  'conversation_id': 'c-1',
  'sender_id': 1,
  'seq': 5,
  'type': 'text',
  'content': {'text': 'hello'},
  'reactions': {},
  'reaction_details': [
    {
      'emoji': '👍',
      'count': 1,
      'user_ids': [2],
      'first_added_at': '2026-11-18T10:00:00+00:00',
    },
  ],
  'created_at': '2026-11-18T09:59:00+00:00',
  'edited_at': null,
  'seen': false,
};

void main() {
  late FakeHttpAdapter adapter;

  ChatApi apiWith(FakeHttpHandler handler) {
    adapter = FakeHttpAdapter(handler);
    return ChatApi(
      ApiClient(
        sessionStore: SessionStore(MemoryKeyValueStorage()),
        dio: Dio()..httpClientAdapter = adapter,
      ),
    );
  }

  ChatApi apiReturningMessage() =>
      apiWith((_) => jsonResponse(_textMessage, 200));

  test('openDirect posts to the direct conversation for a user', () async {
    final api = apiWith(
      (_) => jsonResponse({
        'id': 'c-1',
        'type': 'direct',
        'created_at': '2026-11-01T00:00:00+00:00',
        'notifications': 2,
      }, 200),
    );

    final conversation = await api.openDirect(2);

    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.path, endsWith('/chats/v1/direct/2'));
    expect(conversation.id, 'c-1');
    expect(conversation.notifications, 2);
  });

  test('messages sends the page size and the before cursor', () async {
    final api = apiWith((_) => jsonResponse([_textMessage], 200));

    final messages = await api.messages(
      'c-1',
      before: DateTime.utc(2026, 11, 18, 9, 59),
    );

    final uri = Uri.parse(adapter.requests.single.path);
    expect(uri.path, endsWith('/chats/v1/c-1/messages'));
    expect(uri.queryParameters['limit'], '20');
    expect(uri.queryParameters['before'], '2026-11-18T09:59:00.000Z');
    expect(messages.single.text, 'hello');
  });

  test('messages parses reactions and the seen flag', () async {
    final api = apiWith((_) => jsonResponse([_textMessage], 200));

    final message = (await api.messages('c-1')).single;

    expect(message.reactions.single.emoji, '👍');
    expect(message.reactions.single.count, 1);
    expect(message.reactions.single.isReactedBy(2), isTrue);
    expect(message.createdAt, DateTime.utc(2026, 11, 18, 9, 59));
  });

  test('sendText posts a multipart text field', () async {
    final api = apiReturningMessage();

    await api.sendText('c-1', 'hello');

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.path, endsWith('/chats/v1/c-1/messages'));
    expect(Map.fromEntries((request.data as FormData).fields), {
      'text': 'hello',
    });
  });

  test('sendFile sends the file with its content type', () async {
    final api = apiReturningMessage();

    await api.sendFile(
      'c-1',
      file: const ChatUpload(
        bytes: [1, 2, 3],
        filename: 'photo.png',
        contentType: 'image/png',
      ),
      text: 'look',
    );

    final form = adapter.requests.single.data as FormData;
    expect(Map.fromEntries(form.fields), {'text': 'look'});
    final file = form.files.single;
    expect(file.key, 'file');
    expect(file.value.filename, 'photo.png');
    expect(file.value.contentType.toString(), 'image/png');
  });

  test('reply posts message_id with the text', () async {
    final api = apiReturningMessage();

    await api.reply('c-1', messageId: 'm-9', text: 'agreed');

    final request = adapter.requests.single;
    expect(request.path, endsWith('/chats/v1/c-1/reply'));
    expect(Map.fromEntries((request.data as FormData).fields), {
      'message_id': 'm-9',
      'text': 'agreed',
    });
  });

  test('edit patches the message with its id in the body', () async {
    final api = apiReturningMessage();

    final message = await api.edit('c-1', messageId: 'm-1', text: 'hello!');

    final request = adapter.requests.single;
    expect(request.method, 'PATCH');
    expect(request.path, endsWith('/chats/v1/c-1/messages'));
    expect(request.data, {'text': 'hello!', 'message_id': 'm-1'});
    expect(message.id, 'm-1');
  });

  test('delete sends the message id in the body', () async {
    final api = apiWith((_) => jsonResponse({'message': 'ok'}, 200));

    await api.delete('c-1', messageId: 'm-1');

    final request = adapter.requests.single;
    expect(request.method, 'DELETE');
    expect(request.path, endsWith('/chats/v1/c-1/messages'));
    expect(request.data, {'message_id': 'm-1'});
  });

  test('reactions send the emoji to the message reactions path', () async {
    final api = apiReturningMessage();

    await api.addReaction('c-1', messageId: 'm-1', emoji: '❤️');
    await api.removeReaction('c-1', messageId: 'm-1', emoji: '❤️');

    expect(adapter.requests.map((r) => r.method), ['POST', 'DELETE']);
    for (final request in adapter.requests) {
      expect(request.path, endsWith('/chats/v1/c-1/messages/m-1/reactions'));
      expect(request.data, {'emoji': '❤️'});
    }
  });

  test('markRead posts the uptoSeq and returns the cursor', () async {
    final api = apiWith(
      (_) => jsonResponse({
        'conversation_id': 'c-1',
        'reader_id': 1,
        'last_seen_seq': 5,
        'updated': 2,
      }, 200),
    );

    final cursor = await api.markRead('c-1', uptoSeq: 5);

    expect(adapter.requests.single.path, endsWith('/c-1/read-cursor'));
    expect(adapter.requests.single.data, {'upto_seq': 5});
    expect(cursor.lastSeenSeq, 5);
    expect(cursor.updated, 2);
  });

  test('errors carry the backend key', () async {
    final api = apiWith(
      (_) => jsonResponse({'detail': 'conversations.error.empty_message'}, 400),
    );

    await expectLater(
      api.sendText('c-1', ''),
      throwsA(
        isA<ApiFailure>().having(
          (f) => f.messageKey,
          'messageKey',
          'conversations.error.empty_message',
        ),
      ),
    );
  });

  test('ChatFileRules matches the backend limits', () {
    expect(ChatFileRules.maxBytes, 15 * 1024 * 1024);
    expect(ChatFileRules.allowedContentTypes, contains('image/png'));
    expect(ChatFileRules.allowedContentTypes, isNot(contains('image/svg+xml')));
  });
}
