import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:amber_mobile_client/core/config/app_config.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:web_socket_channel/web_socket_channel.dart';

enum RealtimeConnectionState { connecting, connected, failed, disconnected }

/// Delay before reconnect attempt [attempt] (0-based): 1s, 2s, 4s ... capped at 30s.
Duration reconnectDelay(int attempt) =>
    Duration(seconds: min(30, 1 << min(attempt, 5)));

/// Parses a server message into a JSON object, or returns null if it is not one.
Map<String, dynamic>? decodeRealtimeEvent(Object? raw) {
  if (raw is! String) return null;

  try {
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

/// Keeps one WebSocket open: heartbeat, reconnect with backoff, and routing
/// of events by their `event` name.
class RealtimeClient {
  RealtimeClient({
    required this.sessionId,
    required this.readAccessToken,
    required this.refreshAccessToken,
    this.baseUrl = AppConfig.wsBaseUrl,
    this.heartbeatInterval = const Duration(seconds: 30),
  });

  final String sessionId;
  final Future<String?> Function() readAccessToken;

  /// Called when the server rejects the token (close code 1008).
  final Future<bool> Function() refreshAccessToken;
  final String baseUrl;
  final Duration heartbeatInterval;

  final _states = StreamController<RealtimeConnectionState>.broadcast();
  final _events = StreamController<Map<String, dynamic>>.broadcast();

  RealtimeConnectionState _state = RealtimeConnectionState.disconnected;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeat;
  Timer? _reconnect;
  bool _running = false;
  int _attempt = 0;

  RealtimeConnectionState get state => _state;

  Stream<RealtimeConnectionState> get states => _states.stream;

  /// Events whose `event` field equals [name].
  Stream<Map<String, dynamic>> on(String name) =>
      _events.stream.where((event) => event['event'] == name);

  Future<void> connect() async {
    if (_running) return;

    _running = true;
    await _open();
  }

  Future<void> disconnect() async {
    _running = false;
    _reconnect?.cancel();
    _heartbeat?.cancel();
    await _subscription?.cancel();
    _subscription = null;

    final channel = _channel;
    _channel = null;
    await channel?.sink.close(status.normalClosure);
    _setState(RealtimeConnectionState.disconnected);
  }

  Future<void> dispose() async {
    await disconnect();
    await _states.close();
    await _events.close();
  }

  Future<void> _open() async {
    _setState(RealtimeConnectionState.connecting);

    final token = await readAccessToken();
    if (token == null) return _stop();

    final uri = Uri.parse('$baseUrl/ping')
        .replace(queryParameters: {'token': token, 'session_id': sessionId});
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    _subscription = channel.stream.listen(
      _onMessage,
      onError: (Object _) => _onClosed(channel),
      onDone: () => _onClosed(channel),
    );

    try {
      await channel.ready;
    } on Object {
      // The stream callbacks handle the closed connection.
      return;
    }
    if (!identical(channel, _channel)) return;

    _attempt = 0;
    _setState(RealtimeConnectionState.connected);
    _startHeartbeat(channel);
  }

  void _startHeartbeat(WebSocketChannel channel) {
    _heartbeat?.cancel();
    channel.sink.add('ping');
    _heartbeat = Timer.periodic(
      heartbeatInterval,
      (_) => channel.sink.add('ping'),
    );
  }

  void _onMessage(Object? raw) {
    final event = decodeRealtimeEvent(raw);
    if (event != null && !_events.isClosed) _events.add(event);
  }

  void _onClosed(WebSocketChannel channel) {
    if (!identical(channel, _channel)) return;

    _heartbeat?.cancel();
    _subscription?.cancel();
    _subscription = null;
    _channel = null;
    if (!_running) return;

    _setState(RealtimeConnectionState.failed);
    _scheduleReconnect(refreshFirst: channel.closeCode == 1008);
  }

  void _scheduleReconnect({required bool refreshFirst}) {
    _reconnect?.cancel();
    _reconnect = Timer(reconnectDelay(_attempt++), () async {
      if (!_running) return;

      try {
        if (refreshFirst && !await refreshAccessToken()) return _stop();
        await _open();
      } on Object {
        // A network error during refresh or open: try again later.
        _scheduleReconnect(refreshFirst: refreshFirst);
      }
    });
  }

  void _stop() {
    _running = false;
    _heartbeat?.cancel();
    _setState(RealtimeConnectionState.disconnected);
  }

  void _setState(RealtimeConnectionState next) {
    if (_state == next) return;

    _state = next;
    if (!_states.isClosed) _states.add(next);
  }
}
