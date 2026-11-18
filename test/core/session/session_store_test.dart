import 'package:amber_mobile_client/core/session/key_value_storage.dart';
import 'package:amber_mobile_client/core/session/session_store.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage implements KeyValueStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  late _MemoryStorage storage;
  late SessionStore store;

  setUp(() {
    storage = _MemoryStorage();
    store = SessionStore(storage);
  });

  test('returns null when no refresh token is stored', () async {
    expect(await store.readRefreshToken(), isNull);
  });

  test('writes, reads and clears the refresh token', () async {
    await store.writeRefreshToken('refresh-1');
    expect(await store.readRefreshToken(), 'refresh-1');

    await store.clearRefreshToken();
    expect(await store.readRefreshToken(), isNull);
  });

  test('creates a session id once and reuses it', () async {
    final first = await store.getOrCreateSessionId();
    final second = await store.getOrCreateSessionId();

    expect(first, isNotEmpty);
    expect(second, first);
    expect(storage.values['amber.wsSessionId'], first);
  });

  test('replaces an empty stored session id', () async {
    storage.values['amber.wsSessionId'] = '';

    final id = await store.getOrCreateSessionId();

    expect(id, isNotEmpty);
    expect(storage.values['amber.wsSessionId'], id);
  });
}
