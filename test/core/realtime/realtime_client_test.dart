import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:amber_mobile_client/core/realtime/realtime_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reconnectDelay', () {
    test('doubles from one second and caps at thirty', () {
      expect(reconnectDelay(0), const Duration(seconds: 1));
      expect(reconnectDelay(1), const Duration(seconds: 2));
      expect(reconnectDelay(2), const Duration(seconds: 4));
      expect(reconnectDelay(10), const Duration(seconds: 30));
    });
  });

  group('decodeRealtimeEvent', () {
    test('returns the JSON object for valid events', () {
      expect(decodeRealtimeEvent('{"event":"user_connected"}'), {
        'event': 'user_connected',
      });
    });

    test('ignores non-JSON and non-object messages', () {
      expect(decodeRealtimeEvent('pong'), isNull);
      expect(decodeRealtimeEvent('[1,2]'), isNull);
      expect(decodeRealtimeEvent(42), isNull);
    });
  });

  group('RealtimeClient', () {
    late HttpServer server;
    late String baseUrl;
    final requestUris = <Uri>[];
    final accepted = StreamController<WebSocket>.broadcast();

    setUp(() async {
      requestUris.clear();
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      baseUrl = 'ws://localhost:${server.port}/ws';
      server.listen((request) async {
        requestUris.add(request.uri);
        accepted.add(await WebSocketTransformer.upgrade(request));
      });
    });

    tearDown(() async {
      await server.close(force: true);
    });

    RealtimeClient clientWith({
      Future<bool> Function()? refresh,
      Duration heartbeat = const Duration(seconds: 30),
    }) {
      final client = RealtimeClient(
        sessionId: 'session-1',
        baseUrl: baseUrl,
        readAccessToken: () async => 'token-1',
        refreshAccessToken: refresh ?? () async => false,
        heartbeatInterval: heartbeat,
      );
      addTearDown(client.dispose);
      return client;
    }

    test('sends token, session id and heartbeat, then routes events', () async {
      final client = clientWith();
      final messages = StreamController<dynamic>();
      final socketFuture = accepted.stream.first;

      final event = client.on('user_connected').first;
      await client.connect();
      final socket = await socketFuture;
      socket.listen(messages.add);

      expect(requestUris.single.queryParameters, {
        'token': 'token-1',
        'session_id': 'session-1',
      });
      expect(await messages.stream.first, 'ping');
      expect(client.state, RealtimeConnectionState.connected);

      socket.add(jsonEncode({'event': 'user_connected', 'username': 'ana'}));
      expect((await event)['username'], 'ana');

      await client.disconnect();
      expect(client.state, RealtimeConnectionState.disconnected);
    });

    test('repeats the heartbeat on the configured interval', () async {
      final client = clientWith(heartbeat: const Duration(milliseconds: 20));
      final messages = StreamController<dynamic>();
      final socketFuture = accepted.stream.first;

      await client.connect();
      (await socketFuture).listen(messages.add);

      final received = await messages.stream.take(3).toList();
      expect(received, everyElement('ping'));
    });

    test('refreshes the token and reconnects after a 1008 close', () async {
      var refreshCalls = 0;
      final client = clientWith(
        refresh: () async {
          refreshCalls++;
          return true;
        },
      );
      final socketFuture = accepted.stream.first;

      await client.connect();
      final first = await socketFuture;
      final secondFuture = accepted.stream.first;
      await first.close(1008, 'expired');

      await secondFuture.timeout(const Duration(seconds: 5));
      expect(refreshCalls, 1);
      expect(requestUris, hasLength(2));
    });
  });
}
