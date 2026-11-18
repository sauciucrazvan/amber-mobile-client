import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';
import 'package:dio/dio.dart';

/// Calls the `/contacts/v1/*` endpoints. Every method throws [ApiFailure].
class ContactsApi {
  ContactsApi(this._client);

  final ApiClient _client;

  Future<List<Contact>> list() =>
      _getList('/contacts/v1/list', Contact.fromJson);

  Future<List<ContactRequest>> requests() =>
      _getList('/contacts/v1/requests', ContactRequest.fromJson);

  Future<List<BlockedUser>> blocked() =>
      _getList('/contacts/v1/blocked', BlockedUser.fromJson);

  Future<ContactProfile> profile(String username) async {
    final response = await _guard(
      () => _client.request<Map<String, dynamic>>(
        '/contacts/v1/profile/${Uri.encodeComponent(username)}',
      ),
    );
    return ContactProfile.fromJson(response.data!);
  }

  /// Sends a friend request by username or email.
  Future<void> sendRequest(String identifier) =>
      _send('POST', '/contacts/v1/request', {'identifier': identifier});

  Future<void> accept(String username) =>
      _send('POST', '/contacts/v1/accept', {'username': username});

  Future<void> decline(String username) =>
      _send('POST', '/contacts/v1/decline', {'username': username});

  Future<void> remove(String username) =>
      _send('DELETE', '/contacts/v1/remove', {'username': username});

  Future<void> block(String username) =>
      _send('PUT', '/contacts/v1/block', {'username': username});

  Future<void> unblock(String username) =>
      _send('DELETE', '/contacts/v1/unblock', {'username': username});

  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final response = await _guard(() => _client.request<List<dynamic>>(path));
    return [
      for (final item in response.data ?? const [])
        fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> _send(String method, String path, Map<String, Object> data) {
    return _guard(
      () => _client.request<void>(path, method: method, data: data),
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
