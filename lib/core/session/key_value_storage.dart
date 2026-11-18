import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal string storage, so session logic can be tested without the plugin.
abstract interface class KeyValueStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Keychain on iOS, Keystore on Android.
class SecureKeyValueStorage implements KeyValueStorage {
  const SecureKeyValueStorage([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
