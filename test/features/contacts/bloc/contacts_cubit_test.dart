import 'dart:async';

import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/session/session_store.dart';
import 'package:amber_mobile_client/features/contacts/bloc/contacts_cubit.dart';
import 'package:amber_mobile_client/features/contacts/data/contacts_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/memory_key_value_storage.dart';

Map<String, Object?> _user(int id, String username, {bool online = false}) => {
  'id': id,
  'username': username,
  'full_name': username.toUpperCase(),
  'avatar_url': null,
  'online': online,
  'last_active_at': null,
};

Map<String, Object?> _contact(int id, String username, String lastAction) => {
  'user': _user(id, username),
  'created_at': '2026-11-01T00:00:00+00:00',
  'last_action_at': lastAction,
  'notifications': 0,
  'last_message': null,
};

Map<String, Object?> _contactsEvent(
  String event,
  Map<String, Object?> payload,
) => {'type': 'contacts', 'event': event, 'payload': payload};

void main() {
  late StreamController<Map<String, dynamic>> events;
  late FakeHttpAdapter adapter;

  Future<ContactsCubit> loadedCubit({
    List<Object?> contacts = const [],
    List<Object?> requests = const [],
  }) async {
    adapter = FakeHttpAdapter((options) {
      final path = options.path;
      if (path.endsWith('/contacts/v1/list')) {
        return jsonResponse(contacts, 200);
      }
      if (path.endsWith('/contacts/v1/requests')) {
        return jsonResponse(requests, 200);
      }
      return jsonResponse({'message': 'ok'}, 200);
    });
    events = StreamController<Map<String, dynamic>>.broadcast();
    final cubit = ContactsCubit(
      api: ContactsApi(
        ApiClient(
          sessionStore: SessionStore(MemoryKeyValueStorage()),
          dio: Dio()..httpClientAdapter = adapter,
        ),
      ),
      events: events.stream,
    );
    addTearDown(cubit.close);
    addTearDown(events.close);
    await cubit.load();
    return cubit;
  }

  Future<void> emitEvent(Map<String, dynamic> event) async {
    events.add(event);
    await Future<void>.delayed(Duration.zero);
  }

  List<String> usernames(ContactsCubit cubit) => [
    for (final c in cubit.state.contacts) c.user.username,
  ];

  test('load sorts contacts by last action, newest first', () async {
    final cubit = await loadedCubit(
      contacts: [
        _contact(2, 'bob', '2026-11-10T00:00:00+00:00'),
        _contact(3, 'cara', '2026-11-12T00:00:00+00:00'),
      ],
    );

    expect(cubit.state.status, ContactsStatus.loaded);
    expect(usernames(cubit), ['cara', 'bob']);
  });

  test('a failed load reports failed', () async {
    adapter = FakeHttpAdapter((_) => jsonResponse({'detail': 'x'}, 500));
    final cubit = ContactsCubit(
      api: ContactsApi(
        ApiClient(
          sessionStore: SessionStore(MemoryKeyValueStorage()),
          dio: Dio()..httpClientAdapter = adapter,
        ),
      ),
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.status, ContactsStatus.failed);
  });

  test('accept moves the request into contacts', () async {
    final cubit = await loadedCubit(
      requests: [
        {'user': _user(4, 'dan'), 'created_at': '2026-11-18T00:00:00+00:00'},
      ],
    );

    await cubit.accept(cubit.state.requests.single);

    expect(cubit.state.requests, isEmpty);
    expect(usernames(cubit), ['dan']);
    expect(adapter.requests.last.data, {'username': 'dan'});
  });

  test('decline removes the request', () async {
    final cubit = await loadedCubit(
      requests: [
        {'user': _user(4, 'dan'), 'created_at': '2026-11-18T00:00:00+00:00'},
      ],
    );

    await cubit.decline(cubit.state.requests.single);

    expect(cubit.state.requests, isEmpty);
    expect(cubit.state.contacts, isEmpty);
  });

  test('block and remove drop the contact', () async {
    final cubit = await loadedCubit(
      contacts: [
        _contact(2, 'bob', '2026-11-10T00:00:00+00:00'),
        _contact(3, 'cara', '2026-11-12T00:00:00+00:00'),
      ],
    );

    await cubit.block(cubit.state.contacts.first.user);
    expect(usernames(cubit), ['bob']);
    expect(adapter.requests.last.method, 'PUT');

    await cubit.remove(cubit.state.contacts.single.user);
    expect(cubit.state.contacts, isEmpty);
    expect(adapter.requests.last.method, 'DELETE');
  });

  group('events', () {
    test('request received and removed', () async {
      final cubit = await loadedCubit();

      await emitEvent(
        _contactsEvent('contact.request.received', {
          'user': _user(5, 'eva'),
          'created_at': '2026-11-18T00:00:00+00:00',
        }),
      );
      expect(cubit.state.requests.single.user.username, 'eva');

      await emitEvent(
        _contactsEvent('contact.request.removed', {
          'user_id': 5,
          'username': 'eva',
        }),
      );
      expect(cubit.state.requests, isEmpty);
    });

    test('accepted adds the contact once and clears the request', () async {
      final cubit = await loadedCubit(
        requests: [
          {'user': _user(5, 'eva'), 'created_at': '2026-11-18T00:00:00+00:00'},
        ],
      );
      final accepted = _contactsEvent('contact.accepted', {
        'user': _user(5, 'eva', online: true),
        'created_at': '2026-11-18T00:00:00+00:00',
        'last_action_at': '2026-11-18T01:00:00+00:00',
      });

      await emitEvent(accepted);
      await emitEvent(accepted);

      expect(usernames(cubit), ['eva']);
      expect(cubit.state.contacts.single.user.online, isTrue);
      expect(cubit.state.requests, isEmpty);
    });

    test('removed drops the contact by either id', () async {
      final cubit = await loadedCubit(
        contacts: [_contact(2, 'bob', '2026-11-10T00:00:00+00:00')],
      );

      await emitEvent(
        _contactsEvent('contact.removed', {'user_id': 1, 'other_user_id': 2}),
      );

      expect(cubit.state.contacts, isEmpty);
    });

    test('profile updated changes the name', () async {
      final cubit = await loadedCubit(
        contacts: [_contact(2, 'bob', '2026-11-10T00:00:00+00:00')],
      );

      await emitEvent(
        _contactsEvent('contact.profile.updated', {
          'user': {..._user(2, 'bob'), 'full_name': 'Robert'},
        }),
      );

      expect(cubit.state.contacts.single.user.displayName, 'Robert');
    });

    test('last action updated reorders the list', () async {
      final cubit = await loadedCubit(
        contacts: [
          _contact(2, 'bob', '2026-11-10T00:00:00+00:00'),
          _contact(3, 'cara', '2026-11-12T00:00:00+00:00'),
        ],
      );

      await emitEvent(
        _contactsEvent('contact.last_action.updated', {
          'user_id': 2,
          'last_action_at': '2026-11-18T00:00:00+00:00',
        }),
      );

      expect(usernames(cubit), ['bob', 'cara']);
    });

    test('last message updated sets and clears the preview', () async {
      final cubit = await loadedCubit(
        contacts: [_contact(2, 'bob', '2026-11-10T00:00:00+00:00')],
      );

      await emitEvent(
        _contactsEvent('contact.last_message.updated', {
          'user_id': 2,
          'last_message': {
            'sender_id': 2,
            'type': 'text',
            'content': {'text': 'hello'},
            'created_at': '2026-11-18T00:00:00+00:00',
          },
        }),
      );
      expect(cubit.state.contacts.single.lastMessage?.text, 'hello');

      await emitEvent(
        _contactsEvent('contact.last_message.updated', {
          'user_id': 2,
          'last_message': null,
        }),
      );
      expect(cubit.state.contacts.single.lastMessage, isNull);
    });

    test('presence toggles online', () async {
      final cubit = await loadedCubit(
        contacts: [_contact(2, 'bob', '2026-11-10T00:00:00+00:00')],
      );

      await emitEvent({
        'type': 'presence',
        'event': 'user_connected',
        'username': 'bob',
        'online': true,
      });
      expect(cubit.state.contacts.single.user.online, isTrue);

      await emitEvent({
        'type': 'presence',
        'event': 'user_disconnected',
        'username': 'bob',
        'online': false,
      });
      expect(cubit.state.contacts.single.user.online, isFalse);
      expect(cubit.state.contacts.single.user.lastActiveAt, isNotNull);
    });
  });
}
