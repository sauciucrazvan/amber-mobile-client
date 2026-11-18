import 'package:amber_mobile_client/core/config/app_config.dart';
import 'package:amber_mobile_client/core/session/session_store.dart';
import 'package:dio/dio.dart';

class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  factory TokenPair.fromJson(Map<String, dynamic> json) => TokenPair(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
  );

  final String accessToken;
  final String refreshToken;
}

/// Sends API requests with the access token and refreshes it once on 401.
class ApiClient {
  ApiClient({required this.sessionStore, Dio? dio, this.onSessionExpired})
    : _dio = dio ?? Dio() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _attachAccessToken,
        onError: _retryOnUnauthorized,
      ),
    );
  }

  final SessionStore sessionStore;
  final Dio _dio;

  /// Called when the session is cleared after a failed refresh. Assignable
  /// after construction so the auth layer can be wired in later.
  void Function()? onSessionExpired;

  String? _accessToken;
  Future<bool>? _refreshInFlight;

  String? get accessToken => _accessToken;

  Future<Response<T>> request<T>(
    String path, {
    String method = 'GET',
    Object? data,
    String? contentType,
  }) {
    return _dio.request<T>(
      AppConfig.apiUrl(path),
      data: data,
      options: Options(method: method, contentType: contentType),
    );
  }

  Future<void> saveTokens(TokenPair tokens) async {
    _accessToken = tokens.accessToken;
    await sessionStore.writeRefreshToken(tokens.refreshToken);
  }

  /// Gets a new access token from the stored refresh token on app start.
  Future<bool> restoreSession() => refresh();

  /// Refreshes the access token. Concurrent callers share one request.
  Future<bool> refresh() {
    return _refreshInFlight ??= _refresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<void> clearSession() async {
    await signOut();
    onSessionExpired?.call();
  }

  /// Forgets the tokens without reporting an expired session.
  Future<void> signOut() async {
    _accessToken = null;
    await sessionStore.clearRefreshToken();
  }

  Future<bool> _refresh() async {
    final refreshToken = await sessionStore.readRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        AppConfig.apiUrl('/auth/v1/refresh'),
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'skipAuth': true}),
      );
      await saveTokens(TokenPair.fromJson(response.data!));
      return true;
    } on DioException catch (error) {
      // The server rejected the refresh token: the session is over.
      // Network errors keep the session so the user is not logged out offline.
      if (error.response != null) {
        await clearSession();
        return false;
      }
      rethrow;
    }
  }

  void _attachAccessToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final token = _accessToken;
    if (token != null && options.extra['skipAuth'] != true) {
      options.headers['Authorization'] = 'Bearer $token';
      options.extra['auth'] = true;
    }
    handler.next(options);
  }

  Future<void> _retryOnUnauthorized(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final options = error.requestOptions;
    final shouldRetry =
        error.response?.statusCode == 401 &&
        options.extra['auth'] == true &&
        options.extra['retried'] != true;
    if (!shouldRetry) return handler.next(error);

    try {
      if (!await refresh()) return handler.next(error);

      options.extra['retried'] = true;
      handler.resolve(await _dio.fetch(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}
