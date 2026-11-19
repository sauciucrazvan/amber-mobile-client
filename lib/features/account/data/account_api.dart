import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:dio/dio.dart';

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

  Future<void> _patch(String path, Map<String, Object> data) async {
    try {
      await _client.request<void>(path, method: 'PATCH', data: data);
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}
