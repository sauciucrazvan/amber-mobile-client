import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:amber_mobile_client/core/session/session_store.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:amber_mobile_client/features/contacts/data/contacts_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/memory_key_value_storage.dart';

void main() {
  late FakeHttpAdapter adapter;

  ContactsApi apiWith(FakeHttpHandler handler) {
    adapter = FakeHttpAdapter(handler);
    return ContactsApi(
      ApiClient(
        sessionStore: SessionStore(MemoryKeyValueStorage()),
        dio: Dio()..httpClientAdapter = adapter,
      ),
    );
  }

  test('list parses contacts with last message and counts', () async {
    final api = apiWith(
      (_) => jsonResponse([
        {
          'user': {
            'id': 2,
            'username': 'bob',
            'full_name': 'Bob Ionescu',
            'avatar_url': null,
            'online': true,
            'last_active_at': '2026-11-18T10:00:00+00:00',
          },
          'created_at': '2026-11-01T09:00:00+00:00',
          'last_action_at': '2026-11-18T10:00:00+00:00',
          'notifications': 3,
          'last_message': {
            'sender_id': 2,
            'type': 'text',
            'content': {'text': 'hey'},
            'created_at': '2026-11-18T10:00:00+00:00',
          },
        },
      ], 200),
    );

    final contacts = await api.list();

    final contact = contacts.single;
    expect(contact.user.displayName, 'Bob Ionescu');
    expect(contact.user.online, isTrue);
    expect(contact.notifications, 3);
    expect(contact.lastMessage?.text, 'hey');
    expect(contact.lastActionAt, DateTime.utc(2026, 11, 18, 10));
  });

  test('requests and blocked parse their entries', () async {
    final api = apiWith((options) {
      if (options.path.endsWith('/requests')) {
        return jsonResponse([
          {
            'user': {'id': 3, 'username': 'cara', 'full_name': null},
            'created_at': '2026-11-18T08:00:00',
          },
        ], 200);
      }
      return jsonResponse([
        {
          'user': {'id': 4, 'username': 'dan'},
          'created_at': '2026-11-17T08:00:00+00:00',
        },
      ], 200);
    });

    final requests = await api.requests();
    final blocked = await api.blocked();

    expect(requests.single.user.displayName, 'cara');
    expect(requests.single.createdAt, DateTime.utc(2026, 11, 18, 8));
    expect(blocked.single.username, 'dan');
  });

  test('mutations use the backend methods, paths and bodies', () async {
    final api = apiWith((_) => jsonResponse({'message': 'ok'}, 200));

    await api.sendRequest('bob@example.com');
    await api.accept('bob');
    await api.decline('cara');
    await api.remove('bob');
    await api.block('dan');
    await api.unblock('dan');

    expect(
      [
        for (final r in adapter.requests)
          '${r.method} ${Uri.parse(r.path).path} ${r.data}',
      ],
      [
        'POST /api/contacts/v1/request {identifier: bob@example.com}',
        'POST /api/contacts/v1/accept {username: bob}',
        'POST /api/contacts/v1/decline {username: cara}',
        'DELETE /api/contacts/v1/remove {username: bob}',
        'PUT /api/contacts/v1/block {username: dan}',
        'DELETE /api/contacts/v1/unblock {username: dan}',
      ],
    );
  });

  test('profile parses bio and member since', () async {
    final api = apiWith(
      (_) => jsonResponse({
        'id': 2,
        'username': 'bob',
        'full_name': 'Bob',
        'avatar_url': null,
        'registered_at': '2026-01-02T00:00:00+00:00',
        'last_active_at': null,
        'bio': 'Hi there',
        'online': false,
        'verified': true,
        'disabled': false,
      }, 200),
    );

    final profile = await api.profile('bob');

    expect(adapter.requests.single.path, endsWith('/contacts/v1/profile/bob'));
    expect(profile.bio, 'Hi there');
    expect(profile.registeredAt, DateTime.utc(2026, 1, 2));
    expect(profile.user.username, 'bob');
  });

  test('errors carry the backend key', () async {
    final api = apiWith(
      (_) => jsonResponse({'detail': 'contacts.already_added'}, 400),
    );

    await expectLater(
      api.sendRequest('bob'),
      throwsA(
        isA<ApiFailure>().having(
          (f) => f.messageKey,
          'messageKey',
          'contacts.already_added',
        ),
      ),
    );
  });

  test('parseServerTime reads naive timestamps as UTC', () {
    expect(
      parseServerTime('2026-11-18T08:00:00'),
      DateTime.utc(2026, 11, 18, 8),
    );
    expect(parseServerTime(null), isNull);
  });
}
