import 'package:amber_mobile_client/features/calls/data/call_models.dart';

/// One message from the server about a call. The server sends these over the
/// WebSocket. Each one has the `call_id` it is about.
sealed class CallSignal {
  const CallSignal(this.callId);

  final String callId;
}

/// The server accepted our invite and gave the call its id.
class CallInviteAck extends CallSignal {
  const CallInviteAck(super.callId);
}

/// Someone is calling us.
class CallRinging extends CallSignal {
  const CallRinging(super.callId, {required this.peer, required this.mode});

  final CallPeer peer;
  final CallMode mode;
}

/// The callee answered; the caller should send an offer.
class CallAccepted extends CallSignal {
  const CallAccepted(super.callId);
}

class CallRejected extends CallSignal {
  const CallRejected(super.callId);
}

/// The caller hung up before the call was answered.
class CallCanceled extends CallSignal {
  const CallCanceled(super.callId);
}

/// Either side ended the call. [reason] is the backend's `end_reason`.
class CallEnded extends CallSignal {
  const CallEnded(super.callId, {this.reason});

  final String? reason;
}

class CallMissed extends CallSignal {
  const CallMissed(super.callId);
}

class CallFailed extends CallSignal {
  const CallFailed(super.callId);
}

/// The same user answered on another device.
class CallTerminatedElsewhere extends CallSignal {
  const CallTerminatedElsewhere(super.callId);
}

/// WebRTC session description from the peer.
class CallOffer extends CallSignal {
  const CallOffer(super.callId, {required this.sdp});

  final String sdp;
}

class CallAnswer extends CallSignal {
  const CallAnswer(super.callId, {required this.sdp});

  final String sdp;
}

/// The peer's microphone and camera state.
class CallMediaState extends CallSignal {
  const CallMediaState(
    super.callId, {
    required this.audioEnabled,
    required this.videoEnabled,
  });

  final bool audioEnabled;
  final bool videoEnabled;
}

/// The server refused something about a call.
class CallError extends CallSignal {
  const CallError(this.code, this.message) : super('');

  final String code;
  final String message;
}

/// Turns one raw WebSocket message into a [CallSignal], or null when the
/// message is not about calls.
CallSignal? parseCallSignal(Map<String, dynamic> message) {
  final payload = (message['payload'] as Map<String, dynamic>?) ?? const {};
  final event = message['event'] as String?;
  return switch (message['type']) {
    'call' => _callState(event, payload),
    'ack' when event == 'call.invite' => CallInviteAck(
      payload['call_id'] as String,
    ),
    'webrtc' => _webRtc(event, payload),
    'error' => _error(message),
    _ => null,
  };
}

CallSignal? _callState(String? event, Map<String, dynamic> payload) {
  final callId = payload['call_id'] as String?;
  if (callId == null) return null;
  return switch (event) {
    'ringing' => CallRinging(
      callId,
      peer: CallPeer.fromJson(payload['from'] as Map<String, dynamic>),
      mode: CallMode.parse(payload['call_mode'] ?? payload['mode']),
    ),
    'accepted' || 'call.accepted' => CallAccepted(callId),
    'rejected' => CallRejected(callId),
    'cancel' || 'canceled' => CallCanceled(callId),
    'ended' => CallEnded(callId, reason: payload['end_reason'] as String?),
    'missed' => CallMissed(callId),
    'failed' => CallFailed(callId),
    'call.terminated_elsewhere' => CallTerminatedElsewhere(callId),
    _ => null,
  };
}

CallSignal? _webRtc(String? event, Map<String, dynamic> payload) {
  final callId = payload['call_id'] as String?;
  final data = (payload['data'] as Map<String, dynamic>?) ?? const {};
  if (callId == null) return null;
  return switch (event) {
    'offer' => CallOffer(callId, sdp: data['sdp'] as String),
    'answer' => CallAnswer(callId, sdp: data['sdp'] as String),
    'media-state' => CallMediaState(
      callId,
      audioEnabled: data['audio_enabled'] as bool,
      videoEnabled: data['video_enabled'] as bool,
    ),
    _ => null,
  };
}

CallSignal? _error(Map<String, dynamic> message) {
  final code = (message['code'] as String?) ?? '';
  // Only call and signalling errors are ours. Others belong to chat.
  if (!code.startsWith('call.') && !code.startsWith('signal.')) return null;
  return CallError(code, (message['message'] as String?) ?? '');
}
