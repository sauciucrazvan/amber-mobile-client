import 'package:amber_mobile_client/core/session/key_value_storage.dart';
import 'package:uuid/uuid.dart';

/// Persists the refresh token and the per-install WebSocket session id.
class SessionStore {
  SessionStore(this._storage, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  static const _refreshTokenKey = 'amber.refreshToken';
  static const _sessionIdKey = 'amber.wsSessionId';

  final KeyValueStorage _storage;
  final Uuid _uuid;

  Future<String?> readRefreshToken() => _storage.read(_refreshTokenKey);

  Future<void> writeRefreshToken(String token) =>
      _storage.write(_refreshTokenKey, token);

  Future<void> clearRefreshToken() => _storage.delete(_refreshTokenKey);

  /// Returns the stored session id, creating and saving one on first use.
  Future<String> getOrCreateSessionId() async {
    final stored = await _storage.read(_sessionIdKey);
    if (stored != null && stored.isNotEmpty) return stored;

    final created = _uuid.v4();
    await _storage.write(_sessionIdKey, created);
    return created;
  }
}
