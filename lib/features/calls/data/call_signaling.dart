import 'dart:async';

import 'package:amber_mobile_client/features/calls/data/call_models.dart';
import 'package:amber_mobile_client/features/calls/data/call_signal.dart';

/// Sends call messages and turns the incoming WebSocket messages into
/// [CallSignal]s. Each send returns false when the socket is not open.
class CallSignaling {
  CallSignaling({
    required this.send,
    required Stream<Map<String, dynamic>> incoming,
  }) : signals = incoming
           .map(parseCallSignal)
           .where((signal) => signal != null)
           .map((signal) => signal!);

  final bool Function(Map<String, Object?> message) send;

  /// Call messages from the server, in the order they arrive.
  final Stream<CallSignal> signals;

  bool invite(String username, CallMode mode) =>
      send({'event': 'call.invite', 'to': username, 'mode': mode.name});

  bool accept(String callId) =>
      send({'event': 'call.accept', 'call_id': callId});

  bool reject(String callId) =>
      send({'event': 'call.reject', 'call_id': callId});

  bool cancel(String callId) =>
      send({'event': 'call.cancel', 'call_id': callId});

  bool end(String callId) =>
      send({'event': 'call.end', 'call_id': callId, 'reason': 'ended'});

  bool sendOffer(String callId, String sdp) => _sdp(callId, 'offer', sdp);

  bool sendAnswer(String callId, String sdp) => _sdp(callId, 'answer', sdp);

  bool sendMediaState(
    String callId, {
    required bool audioEnabled,
    required bool videoEnabled,
  }) => send({
    'event': 'call.media-state',
    'call_id': callId,
    'payload': {'audio_enabled': audioEnabled, 'video_enabled': videoEnabled},
  });

  bool _sdp(String callId, String type, String sdp) => send({
    'event': 'webrtc.$type',
    'call_id': callId,
    'payload': {'type': type, 'sdp': sdp},
  });
}
