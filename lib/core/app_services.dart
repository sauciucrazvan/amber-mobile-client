import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/realtime/realtime_client.dart';

/// Long-lived services the signed-in features build on. Provided at the app
/// root so feature screens can create their APIs and subscribe to events.
class AppServices {
  const AppServices({
    required this.apiClient,
    this.realtimeEvents = const Stream.empty(),
    this.realtimeStates = const Stream.empty(),
    this.sendRealtime = _notSent,
  });

  final ApiClient apiClient;

  /// Every event from the WebSocket, while it is connected.
  final Stream<Map<String, dynamic>> realtimeEvents;

  /// Connection changes, for the connecting bar and the failure message.
  final Stream<RealtimeConnectionState> realtimeStates;

  /// Sends a message over the WebSocket. False when it was not sent.
  final bool Function(Map<String, Object?> message) sendRealtime;

  static bool _notSent(Map<String, Object?> message) => false;
}
