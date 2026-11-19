import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/session/session_store.dart';
import 'package:amber_mobile_client/features/account/data/account_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';
import '../../../support/memory_key_value_storage.dart';

void main() {
  test('an avatar uploads as multipart and returns its address', () async {
    final requests = <RequestOptions>[];
    final client = ApiClient(
      sessionStore: SessionStore(MemoryKeyValueStorage()),
      dio: Dio()
        ..httpClientAdapter = FakeHttpAdapter((options) {
          requests.add(options);
          return jsonResponse({
            'message': 'settings.account.avatar.updated',
            'avatar_url': 'https://cdn.example/ana.png',
          }, 200);
        }),
    );

    final url = await AccountApi(client).uploadAvatar(
      bytes: const [137, 80, 78, 71],
      filename: 'ana.png',
      contentType: 'image/png',
    );

    expect(url, 'https://cdn.example/ana.png');
    final upload = requests.single;
    expect(upload.method, 'POST');
    expect(upload.path, endsWith('/account/v1/upload/avatar'));
    expect(upload.data, isA<FormData>());
  });

  test('the avatar types match the server list', () {
    expect(avatarContentTypes, {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
    });
    expect(avatarMaxBytes, 5 * 1024 * 1024);
  });
}
