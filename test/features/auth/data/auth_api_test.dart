import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/session/session_store.dart';
import 'package:amber_mobile_client/features/auth/data/auth_api.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/memory_key_value_storage.dart';

void main() {
  late MemoryKeyValueStorage storage;
  late ApiClient client;
  late FakeHttpAdapter adapter;

  AuthApi apiWith(FakeHttpHandler handler) {
    adapter = FakeHttpAdapter(handler);
    storage = MemoryKeyValueStorage();
    client = ApiClient(
      sessionStore: SessionStore(storage),
      dio: Dio()..httpClientAdapter = adapter,
    );
    return AuthApi(client);
  }

  test('login sends form fields and stores the tokens', () async {
    final api = apiWith(
      (_) => jsonResponse({
        'access_token': 'access-1',
        'refresh_token': 'refresh-1',
        'token_type': 'bearer',
      }, 200),
    );

    await api.login('ana', 'Secret123');

    final request = adapter.requests.single;
    expect(request.path, endsWith('/auth/v1/login'));
    expect(request.contentType, Headers.formUrlEncodedContentType);
    expect(request.data, {'username': 'ana', 'password': 'Secret123'});
    expect(client.accessToken, 'access-1');
    expect(storage.values['amber.refreshToken'], 'refresh-1');
  });

  test('login throws the backend message key', () async {
    final api = apiWith(
      (_) => jsonResponse({'detail': 'login.incorrectCredentials'}, 401),
    );

    await expectLater(
      api.login('ana', 'wrong'),
      throwsA(
        isA<ApiFailure>().having(
          (f) => f.messageKey,
          'messageKey',
          'login.incorrectCredentials',
        ),
      ),
    );
    expect(client.accessToken, isNull);
  });

  test('register sends the backend field names', () async {
    final api = apiWith((_) => jsonResponse({'id': 1}, 201));

    await api.register(
      username: 'ana',
      fullName: 'Ana Pop',
      email: 'ana@example.com',
      password: 'Secret123',
    );

    expect(adapter.requests.single.data, {
      'username': 'ana',
      'password': 'Secret123',
      'email': 'ana@example.com',
      'full_name': 'Ana Pop',
    });
  });

  test('register throws field errors', () async {
    final api = apiWith(
      (_) => jsonResponse({
        'detail': {
          'errors': [
            {'field': 'email', 'error': 'register.emailTaken'},
          ],
        },
      }, 422),
    );

    await expectLater(
      api.register(
        username: 'ana',
        fullName: 'Ana',
        email: 'taken@example.com',
        password: 'Secret123',
      ),
      throwsA(
        isA<ApiFailure>().having((f) => f.fieldErrors, 'fieldErrors', {
          'email': 'register.emailTaken',
        }),
      ),
    );
  });

  test('fetchAccount parses the verified flag', () async {
    final api = apiWith(
      (_) => jsonResponse({
        'id': 7,
        'username': 'ana',
        'full_name': 'Ana Pop',
        'email': 'ana@example.com',
        'verified': false,
      }, 200),
    );

    final account = await api.fetchAccount();

    expect(account.id, 7);
    expect(account.username, 'ana');
    expect(account.verified, isFalse);
  });

  test('verify sends the code as verify_code', () async {
    final api = apiWith(
      (_) => jsonResponse({'message': 'register.verify.success'}, 200),
    );

    await api.verify('123456');

    final request = adapter.requests.single;
    expect(request.path, endsWith('/auth/v1/verify'));
    expect(request.data, {'verify_code': '123456'});
  });

  test('resetPassword sends all recovery fields', () async {
    final api = apiWith(
      (_) => jsonResponse({'message': 'login.recovery.success'}, 200),
    );

    await api.resetPassword(
      username: 'ana',
      code: '654321',
      newPassword: 'NewSecret1',
      newPasswordConfirmation: 'NewSecret1',
    );

    expect(adapter.requests.single.data, {
      'username': 'ana',
      'code': '654321',
      'new_password': 'NewSecret1',
      'new_password_confirmation': 'NewSecret1',
    });
  });
}
