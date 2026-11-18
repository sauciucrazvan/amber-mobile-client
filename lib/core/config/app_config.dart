/// Backend endpoints for the app.
///
/// Override per build with `--dart-define=AMBER_API_BASE_URL=...` and
/// `--dart-define=AMBER_WS_BASE_URL=...`.
abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'AMBER_API_BASE_URL',
    defaultValue: 'https://api.amber.albertgalan.ro/api',
  );

  static const String wsBaseUrl = String.fromEnvironment(
    'AMBER_WS_BASE_URL',
    defaultValue: 'wss://api.amber.albertgalan.ro/ws',
  );

  /// Builds an absolute API URL. Absolute URLs are returned unchanged.
  static String apiUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;

    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$apiBaseUrl$normalizedPath';
  }
}
