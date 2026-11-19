import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:dio/dio.dart';

/// Avatar files the server accepts, by extension. The server takes the type
/// from the upload, so these must match its allowed list.
const avatarContentTypes = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
};

/// The largest avatar the server accepts.
const avatarMaxBytes = 5 * 1024 * 1024;

/// The account changes that save in place: name, bio, password and privacy.
/// Each method throws [ApiFailure] with a translation key on an error.
class AccountApi {
  AccountApi(this._client);

  final ApiClient _client;

  Future<void> updateName(String fullName) =>
      _patch('/account/v1/modify/fullname', {'new_full_name': fullName});

  Future<void> updateBio(String bio) =>
      _patch('/account/v1/modify/bio', {'new_bio': bio});

  Future<void> changePassword({
    required String current,
    required String next,
    required String confirmation,
  }) => _patch('/account/v1/modify/password', {
    'current_password': current,
    'new_password': next,
    'new_password_confirmation': confirmation,
  });

  Future<void> setPrivacy(String setting, {required bool value}) => _patch(
    '/account/v1/settings/privacy',
    {'setting': setting, 'value': value},
  );

  /// Uploads a new avatar and returns its address.
  Future<String> uploadAvatar({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    try {
      final response = await _client.request<Map<String, dynamic>>(
        '/account/v1/upload/avatar',
        method: 'POST',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename: filename,
            contentType: DioMediaType.parse(contentType),
          ),
        }),
      );
      return response.data!['avatar_url'] as String;
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }

  /// Asks for a copy of the account's data, sent by email. The server allows
  /// one request a week.
  Future<void> requestData() => _send('POST', '/account/v1/request/data');

  /// Deletes the account. The server checks the password first.
  Future<void> deleteAccount(String password) =>
      _send('DELETE', '/account/v1/delete', {'password': password});

  Future<void> _patch(String path, Map<String, Object> data) =>
      _send('PATCH', path, data);

  Future<void> _send(
    String method,
    String path, [
    Map<String, Object>? data,
  ]) async {
    try {
      await _client.request<void>(path, method: method, data: data);
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}
