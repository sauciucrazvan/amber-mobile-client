import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/features/auth/data/account.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:dio/dio.dart';

/// Calls the `/auth/v1/*` and `/account/v1/recovery/*` endpoints.
/// Every method throws [ApiFailure] on an error response.
class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  /// Logs in and stores the returned tokens.
  Future<void> login(String username, String password) async {
    final response = await _guard(
      () => _client.request<Map<String, dynamic>>(
        '/auth/v1/login',
        method: 'POST',
        data: {'username': username, 'password': password},
        contentType: Headers.formUrlEncodedContentType,
      ),
    );
    await _client.saveTokens(TokenPair.fromJson(response.data!));
  }

  Future<void> register({
    required String username,
    required String fullName,
    required String email,
    required String password,
  }) {
    return _guard(
      () => _client.request<void>(
        '/auth/v1/register',
        method: 'POST',
        data: {
          'username': username,
          'password': password,
          'email': email,
          'full_name': fullName,
        },
      ),
    );
  }

  Future<Account> fetchAccount() async {
    final response = await _guard(
      () => _client.request<Map<String, dynamic>>('/account/v1/me'),
    );
    return Account.fromJson(response.data!);
  }

  Future<void> requestVerification() {
    return _guard(
      () => _client.request<void>('/auth/v1/verify/request', method: 'POST'),
    );
  }

  Future<void> verify(String code) {
    return _guard(
      () => _client.request<void>(
        '/auth/v1/verify',
        method: 'POST',
        data: {'verify_code': code},
      ),
    );
  }

  Future<void> requestRecovery(String username) {
    return _guard(
      () => _client.request<void>(
        '/account/v1/recovery/request',
        method: 'POST',
        data: {'username': username},
      ),
    );
  }

  Future<void> resetPassword({
    required String username,
    required String code,
    required String newPassword,
    required String newPasswordConfirmation,
  }) {
    return _guard(
      () => _client.request<void>(
        '/account/v1/recovery/reset',
        method: 'POST',
        data: {
          'username': username,
          'code': code,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        },
      ),
    );
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}
