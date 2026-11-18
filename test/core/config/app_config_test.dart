import 'package:amber_mobile_client/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig.apiUrl', () {
    test('appends a path with a leading slash', () {
      expect(
        AppConfig.apiUrl('/auth/v1/refresh'),
        '${AppConfig.apiBaseUrl}/auth/v1/refresh',
      );
    });

    test('adds the missing leading slash', () {
      expect(
        AppConfig.apiUrl('auth/v1/refresh'),
        '${AppConfig.apiBaseUrl}/auth/v1/refresh',
      );
    });

    test('returns absolute URLs unchanged', () {
      const url = 'https://example.com/other';
      expect(AppConfig.apiUrl(url), url);
    });
  });

  test('defaults to the production backend', () {
    expect(AppConfig.apiBaseUrl, 'https://api.amber.albertgalan.ro/api');
    expect(AppConfig.wsBaseUrl, 'wss://api.amber.albertgalan.ro/ws');
  });
}
