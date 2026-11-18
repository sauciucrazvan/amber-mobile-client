import 'package:dio/dio.dart';

/// A failed auth request. [messageKey] is a translation key such as
/// `login.incorrectCredentials`, or plain text when no key applies.
class AuthFailure implements Exception {
  const AuthFailure(this.messageKey, {this.fieldErrors = const {}});

  static const tooManyRequests = 'common.errors.too_many_requests';
  static const fillInput = 'login.fillInput';

  static const unreachable = 'common.connection.failed';

  final String messageKey;

  /// Translation keys per field (`username`, `password`, `full_name`, `email`).
  final Map<String, String> fieldErrors;

  /// Reads the backend's error shapes:
  /// - `{"detail": "login.incorrectCredentials"}`
  /// - `{"detail": {"errors": [{"field": "email", "error": "register.emailTaken"}]}}`
  /// - `{"detail": [...]}`, FastAPI's own validation error for missing fields
  /// - no `detail`, as sent by the rate limiter
  factory AuthFailure.fromDio(DioException error) {
    final response = error.response;
    if (response == null) return const AuthFailure(unreachable);

    final data = response.data;
    final detail = data is Map ? data['detail'] : null;

    if (detail is String && detail.isNotEmpty) return AuthFailure(detail);

    if (detail is Map && detail['errors'] is List) {
      final fieldErrors = <String, String>{
        for (final item in detail['errors'] as List)
          if (item is Map && item['field'] is String && item['error'] is String)
            item['field'] as String: item['error'] as String,
      };
      return AuthFailure(
        fieldErrors.values.firstOrNull ?? fillInput,
        fieldErrors: fieldErrors,
      );
    }

    if (detail is List) return const AuthFailure(fillInput);
    if (response.statusCode == 429) return const AuthFailure(tooManyRequests);
    return AuthFailure('Request failed (${response.statusCode})');
  }

  @override
  String toString() => 'AuthFailure($messageKey, $fieldErrors)';
}
