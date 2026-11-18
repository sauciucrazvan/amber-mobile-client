import 'dart:async';

import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/session/session_store.dart';
import 'package:amber_mobile_client/features/chat/bloc/conversation_cubit.dart';
import 'package:amber_mobile_client/features/chat/data/chat_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/memory_key_value_storage.dart';

const _me = 1;
const _them = 2;
const _conversation = 'c-1';

/// A message as the backend serializes it. `seq` also sets its created time,
/// so paging by `before` works in tests.
Map<String, Object?> _msg(
  int seq, {
  int sender = _them,
  String? id,
  String text = 'hi',
  List<Map<String, Object?>> reactions = const [],
  bool seen = false,
}) {
  final created = DateTime.utc(2026, 11, 18, 10).add(Duration(minutes: seq));
  return {
    'id': id ?? 'm-$seq',
    'conversation_id': _conversation,
    'sender_id': sender,
    'seq': seq,
    'type': 'text',
    'content': {'text': text},
    'reaction_details': reactions,
    'created_at': created.toIso8601String(),
    'edited_at': null,
    'seen': seen,
  };
}

Map<String, dynamic> _event(String name, Map<String, Object?> payload) => {
  'event': name,
  'conversation_id': _conversation,
  'payload': payload,
};

void main() {
  late FakeHttpAdapter adapter;
  late StreamController<Map<String, dynamic>> events;

  Future<ConversationCubit> cubitWith(
    FakeHttpHandler handler, {
    int pageSize = 2,
  }) async {
    adapter = FakeHttpAdapter(handler);
    events = StreamController<Map<String, dynamic>>.broadcast();
    final cubit = ConversationCubit(
      conversationId: _conversation,
      myUserId: _me,
      pageSize: pageSize,
      api: ChatApi(
        ApiClient(
          sessionStore: SessionStore(MemoryKeyValueStorage()),
          dio: Dio()..httpClientAdapter = adapter,
        ),
      ),
      events: events.stream,
    );
    addTearDown(cubit.close);
    addTearDown(events.close);
    return cubit;
  }

  Future<void> emitEvent(Map<String, dynamic> event) async {
    events.add(event);
    await Future<void>.delayed(Duration.zero);
  }

  List<int> seqs(ConversationCubit cubit) => [
    for (final m in cubit.state.messages) m.seq,
  ];

  test('load fetches the newest page in order', () async {
    final cubit = await cubitWith((_) => jsonResponse([_msg(4), _msg(5)], 200));

    await cubit.load();

    expect(cubit.state.status, ConversationStatus.loaded);
    expect(seqs(cubit), [4, 5]);
    expect(cubit.state.hasOlder, isTrue);
  });

  test('loadOlder prepends the page before the oldest message', () async {
    final cubit = await cubitWith((options) {
      final before = Uri.parse(options.path).queryParameters['before'];
      if (before == null) {
        return jsonResponse([_msg(4), _msg(5)], 200);
      }
      return jsonResponse([_msg(2), _msg(3)], 200);
    });
    await cubit.load();

    await cubit.loadOlder();

    expect(seqs(cubit), [2, 3, 4, 5]);
    final before = Uri.parse(adapter.requests.last.path)
        .queryParameters['before'];
    expect(before, DateTime.utc(2026, 11, 18, 10, 4).toIso8601String());
  });

  test('a short page means there is nothing older', () async {
    final cubit = await cubitWith((options) {
      final before = Uri.parse(options.path).queryParameters['before'];
      if (before == null) {
        return jsonResponse([_msg(4), _msg(5)], 200);
      }
      return jsonResponse([_msg(3)], 200);
    });
    await cubit.load();

    await cubit.loadOlder();

    expect(cubit.state.hasOlder, isFalse);
    expect(seqs(cubit), [3, 4, 5]);
  });

  test('a sent message is not duplicated by its own event', () async {
    final cubit = await cubitWith((options) {
      if (options.method == 'POST') {
        return jsonResponse(_msg(6, sender: _me), 200);
      }
      return jsonResponse([_msg(4), _msg(5)], 200);
    });
    await cubit.load();

    await cubit.sendText('hi');
    await emitEvent(
      _event('message.created', {'message': _msg(6, sender: _me)}),
    );

    expect(seqs(cubit), [4, 5, 6]);
  });

  test('events for other conversations are ignored', () async {
    final cubit = await cubitWith((_) => jsonResponse([_msg(4)], 200));
    await cubit.load();

    await emitEvent({
      'event': 'message.created',
      'conversation_id': 'other',
      'payload': {'message': _msg(5)},
    });

    expect(seqs(cubit), [4]);
  });

  test('edited, reacted and deleted events update the message', () async {
    final cubit = await cubitWith((_) => jsonResponse([_msg(4), _msg(5)], 200));
    await cubit.load();

    await emitEvent(
      _event('message.edited', {'message': _msg(4, text: 'edited')}),
    );
    expect(cubit.state.messages.first.text, 'edited');

    await emitEvent(
      _event('message.reacted', {
        'message': _msg(
          5,
          reactions: [
            {
              'emoji': '👍',
              'count': 1,
              'user_ids': [_them],
              'first_added_at': null,
            },
          ],
        ),
      }),
    );
    expect(cubit.state.messages.last.reactions.single.emoji, '👍');

    await emitEvent(_event('message.deleted', {'message_id': 'm-4'}));
    expect(seqs(cubit), [5]);
  });

  test('the other side reading marks my messages up to their seq', () async {
    final cubit = await cubitWith(
      (_) => jsonResponse([
        _msg(4, sender: _me),
        _msg(5, sender: _me),
        _msg(6, sender: _them),
      ], 200),
    );
    await cubit.load();

    await emitEvent(
      _event('conversation.read_cursor.updated', {
        'reader_id': _them,
        'last_seen_seq': 4,
        'last_seen_at': '2026-11-18T10:10:00+00:00',
      }),
    );

    final seen = {for (final m in cubit.state.messages) m.seq: m.seen};
    expect(seen, {4: true, 5: false, 6: false});
  });

  test('my own read cursor does not change the messages', () async {
    final cubit = await cubitWith(
      (_) => jsonResponse([_msg(4, sender: _me)], 200),
    );
    await cubit.load();

    await emitEvent(
      _event('conversation.read_cursor.updated', {
        'reader_id': _me,
        'last_seen_seq': 4,
      }),
    );

    expect(cubit.state.messages.single.seen, isFalse);
  });

  test('react adds my emoji, then removes it when I react again', () async {
    final cubit = await cubitWith((options) {
      if (options.method == 'GET') return jsonResponse([_msg(4)], 200);
      final mine = options.method == 'POST';
      return jsonResponse(
        _msg(
          4,
          reactions: mine
              ? [
                  {
                    'emoji': '❤️',
                    'count': 1,
                    'user_ids': [_me],
                    'first_added_at': null,
                  },
                ]
              : [],
        ),
        200,
      );
    });
    await cubit.load();
    final message = cubit.state.messages.single;

    await cubit.react(message, '❤️');
    expect(adapter.requests.last.method, 'POST');
    expect(cubit.state.messages.single.reactions, hasLength(1));

    await cubit.react(cubit.state.messages.single, '❤️');
    expect(adapter.requests.last.method, 'DELETE');
    expect(cubit.state.messages.single.reactions, isEmpty);
  });

  test('markRead sends the newest loaded seq', () async {
    final cubit = await cubitWith((options) {
      if (options.path.endsWith('/read-cursor')) {
        return jsonResponse({
          'conversation_id': _conversation,
          'reader_id': _me,
          'last_seen_seq': 5,
          'updated': 1,
        }, 200);
      }
      return jsonResponse([_msg(4), _msg(5)], 200);
    });
    await cubit.load();

    await cubit.markRead();

    expect(adapter.requests.last.data, {'upto_seq': 5});
  });
}
