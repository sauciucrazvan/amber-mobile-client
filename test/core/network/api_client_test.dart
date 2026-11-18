import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/session/session_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_adapter.dart';
import '../../support/memory_key_value_storage.dart';

void main() {
  late MemoryKeyValueStorage storage;
  late SessionStore sessionStore;
  var sessionExpired = 0;

  setUp(() {
    storage = MemoryKeyValueStorage();
    sessionStore = SessionStore(storage);
    sessionExpired = 0;
  });

  ApiClient clientWith(FakeHttpAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    return ApiClient(
      sessionStore: sessionStore,
      dio: dio,
      onSessionExpired: () => sessionExpired++,
    );
  }

  test('attaches the bearer token after saving tokens', () async {
    final adapter = FakeHttpAdapter((_) => jsonResponse({'ok': true}, 200));
    final client = clientWith(adapter);

    await client.saveTokens(
      const TokenPair(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );
    await client.request('/users/me');

    expect(adapter.requests.single.headers['Authorization'], 'Bearer access-1');
  });

  test('refreshes once on 401 and retries with the new token', () async {
    final adapter = FakeHttpAdapter((options) {
      if (options.path.endsWith('/auth/v1/refresh')) {
        return jsonResponse({
          'access_token': 'access-2',
          'refresh_token': 'refresh-2',
          'token_type': 'bearer',
        }, 200);
      }
      final token = options.headers['Authorization'];
      return token == 'Bearer access-2'
          ? jsonResponse({'ok': true}, 200)
          : jsonResponse({'detail': 'expired'}, 401);
    });
    final client = clientWith(adapter);
    await client.saveTokens(
      const TokenPair(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );

    final response = await client.request<Map<String, dynamic>>('/users/me');

    expect(response.data, {'ok': true});
    expect(storage.values['amber.refreshToken'], 'refresh-2');
    expect(
      adapter.requests.where((r) => r.path.endsWith('/auth/v1/refresh')),
      hasLength(1),
    );
  });

  test('shares one refresh between concurrent 401 responses', () async {
    final adapter = FakeHttpAdapter((options) {
      if (options.path.endsWith('/auth/v1/refresh')) {
        return jsonResponse({
          'access_token': 'access-2',
          'refresh_token': 'refresh-2',
          'token_type': 'bearer',
        }, 200);
      }
      return options.headers['Authorization'] == 'Bearer access-2'
          ? jsonResponse({'ok': true}, 200)
          : jsonResponse({'detail': 'expired'}, 401);
    });
    final client = clientWith(adapter);
    await client.saveTokens(
      const TokenPair(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );

    await Future.wait([
      client.request('/a'),
      client.request('/b'),
      client.request('/c'),
    ]);

    expect(
      adapter.requests.where((r) => r.path.endsWith('/auth/v1/refresh')),
      hasLength(1),
    );
  });

  test('clears the session when the refresh token is rejected', () async {
    final adapter = FakeHttpAdapter((options) {
      if (options.path.endsWith('/auth/v1/refresh')) {
        return jsonResponse({'detail': 'invalid'}, 401);
      }
      return jsonResponse({'detail': 'expired'}, 401);
    });
    final client = clientWith(adapter);
    await client.saveTokens(
      const TokenPair(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );

    await expectLater(
      client.request('/users/me'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(storage.values.containsKey('amber.refreshToken'), isFalse);
    expect(sessionExpired, 1);
  });

  test('does not refresh for requests without a token', () async {
    final adapter = FakeHttpAdapter(
      (_) => jsonResponse({'detail': 'bad'}, 401),
    );
    final client = clientWith(adapter);
    await sessionStore.writeRefreshToken('refresh-1');

    await expectLater(
      client.request('/auth/v1/login', method: 'POST'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests, hasLength(1));
    expect(
      adapter.requests.single.headers.containsKey('Authorization'),
      isFalse,
    );
    expect(storage.values['amber.refreshToken'], 'refresh-1');
  });

  test('restoreSession returns false when there is no refresh token', () async {
    final client = clientWith(FakeHttpAdapter((_) => jsonResponse({}, 200)));

    expect(await client.restoreSession(), isFalse);
  });

  test('signOut clears tokens without reporting an expired session', () async {
    final client = clientWith(FakeHttpAdapter((_) => jsonResponse({}, 200)));
    await client.saveTokens(
      const TokenPair(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );

    await client.signOut();

    expect(client.accessToken, isNull);
    expect(storage.values.containsKey('amber.refreshToken'), isFalse);
    expect(sessionExpired, 0);
  });

  test('sends the given content type', () async {
    final adapter = FakeHttpAdapter((_) => jsonResponse({}, 200));
    final client = clientWith(adapter);

    await client.request(
      '/auth/v1/login',
      method: 'POST',
      data: {'username': 'ana'},
      contentType: Headers.formUrlEncodedContentType,
    );

    expect(
      adapter.requests.single.contentType,
      Headers.formUrlEncodedContentType,
    );
  });
}
