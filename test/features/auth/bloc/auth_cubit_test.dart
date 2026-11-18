import 'dart:async';
import 'dart:io' show SocketException;

import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/session/session_store.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/auth/data/auth_api.dart';
import 'package:amber_mobile_client/features/auth/data/auth_failure.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/memory_key_value_storage.dart';

Map<String, Object> _tokens(String suffix) => {
  'access_token': 'access-$suffix',
  'refresh_token': 'refresh-$suffix',
  'token_type': 'bearer',
};

Map<String, Object> _me({bool verified = true}) => {
  'id': 1,
  'username': 'ana',
  'full_name': 'Ana Pop',
  'email': 'ana@example.com',
  'verified': verified,
};

void main() {
  late MemoryKeyValueStorage storage;
  late ApiClient client;
  late StreamController<Map<String, dynamic>> accountEvents;
  var connects = 0;
  var disconnects = 0;

  AuthCubit cubitWith(FakeHttpHandler handler) {
    storage = MemoryKeyValueStorage();
    client = ApiClient(
      sessionStore: SessionStore(storage),
      dio: Dio()..httpClientAdapter = FakeHttpAdapter(handler),
    );
    accountEvents = StreamController<Map<String, dynamic>>.broadcast();
    connects = 0;
    disconnects = 0;
    final cubit = AuthCubit(
      api: AuthApi(client),
      client: client,
      connectRealtime: () async => connects++,
      disconnectRealtime: () async => disconnects++,
      accountEvents: accountEvents.stream,
    );
    addTearDown(cubit.close);
    addTearDown(accountEvents.close);
    return cubit;
  }

  group('start', () {
    test('shows login when no session is stored', () async {
      final cubit = cubitWith((_) => jsonResponse({}, 200));

      await cubit.start();

      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(connects, 0);
    });

    test('restores a stored session and connects realtime', () async {
      final cubit = cubitWith((options) {
        if (options.path.endsWith('/auth/v1/refresh')) {
          return jsonResponse(_tokens('2'), 200);
        }
        return jsonResponse(_me(), 200);
      });
      storage.values['amber.refreshToken'] = 'refresh-1';

      await cubit.start();

      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.account?.username, 'ana');
      expect(connects, 1);
    });

    test('shows login when the stored session is rejected', () async {
      final cubit = cubitWith(
        (_) => jsonResponse({'detail': 'Could not validate credentials'}, 401),
      );
      storage.values['amber.refreshToken'] = 'refresh-1';

      await cubit.start();

      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(storage.values.containsKey('amber.refreshToken'), isFalse);
    });

    test('reports unreachable and keeps the session when offline', () async {
      final cubit = cubitWith((_) => throw const SocketException('offline'));
      storage.values['amber.refreshToken'] = 'refresh-1';

      await cubit.start();

      expect(cubit.state.status, AuthStatus.unreachable);
      expect(storage.values['amber.refreshToken'], 'refresh-1');
    });
  });

  test('login loads the account and connects realtime', () async {
    final cubit = cubitWith((options) {
      if (options.path.endsWith('/auth/v1/login')) {
        return jsonResponse(_tokens('1'), 200);
      }
      return jsonResponse(_me(verified: false), 200);
    });

    await cubit.login('ana', 'Secret123');

    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.needsVerification, isTrue);
    expect(connects, 1);
  });

  test('login failure throws and keeps the user signed out', () async {
    final cubit = cubitWith(
      (_) => jsonResponse({'detail': 'login.incorrectCredentials'}, 401),
    );
    await cubit.start();

    await expectLater(cubit.login('ana', 'wrong'), throwsA(isA<AuthFailure>()));
    expect(cubit.state.status, AuthStatus.unauthenticated);
  });

  test('signOut disconnects realtime and clears the session', () async {
    final cubit = cubitWith((options) {
      if (options.path.endsWith('/auth/v1/login')) {
        return jsonResponse(_tokens('1'), 200);
      }
      return jsonResponse(_me(), 200);
    });
    await cubit.login('ana', 'Secret123');

    await cubit.signOut();

    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(disconnects, 1);
    expect(client.accessToken, isNull);
    expect(storage.values.containsKey('amber.refreshToken'), isFalse);
  });

  test('an expired session signs the user out', () async {
    var meCalls = 0;
    final cubit = cubitWith((options) {
      if (options.path.endsWith('/auth/v1/login')) {
        return jsonResponse(_tokens('1'), 200);
      }
      if (options.path.endsWith('/auth/v1/refresh')) {
        return jsonResponse({'detail': 'Could not validate credentials'}, 401);
      }
      meCalls++;
      return meCalls == 1
          ? jsonResponse(_me(), 200)
          : jsonResponse({'detail': 'expired'}, 401);
    });
    await cubit.login('ana', 'Secret123');

    await expectLater(cubit.refreshAccount(), throwsA(isA<AuthFailure>()));

    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(disconnects, 1);
  });

  test('account.updated marks the account verified', () async {
    final cubit = cubitWith((options) {
      if (options.path.endsWith('/auth/v1/login')) {
        return jsonResponse(_tokens('1'), 200);
      }
      return jsonResponse(_me(verified: false), 200);
    });
    await cubit.login('ana', 'Secret123');

    accountEvents.add({
      'type': 'account',
      'event': 'account.updated',
      'payload': {'verified': true},
    });
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.needsVerification, isFalse);
  });
}
