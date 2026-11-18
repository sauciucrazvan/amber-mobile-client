import 'package:amber_mobile_client/core/session/key_value_storage.dart';

/// In-memory [KeyValueStorage] for tests.
class MemoryKeyValueStorage implements KeyValueStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
