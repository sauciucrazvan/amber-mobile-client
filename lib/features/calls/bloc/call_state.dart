import 'package:amber_mobile_client/features/calls/data/call_models.dart';

enum CallPhase {
  /// No call. [CallState.errorKey] may hold a message to show once.
  idle,

  /// We invited someone and are waiting for an answer.
  outgoing,

  /// Someone is calling us, and we have not answered.
  incoming,

  /// Answered; the media is being set up.
  connecting,

  /// Connected.
  inProgress,

  /// The call is over. The summary stays for a few seconds.
  ended,
}

class CallState {
  const CallState({
    this.phase = CallPhase.idle,
    this.callId,
    this.peer,
    this.mode = CallMode.video,
    this.micOn = true,
    this.cameraOn = true,
    this.remoteMicOn = true,
    this.remoteCameraOn = true,
    this.startedAt,
    this.endReason,
    this.errorKey,
  });

  final CallPhase phase;
  final String? callId;
  final CallPeer? peer;
  final CallMode mode;
  final bool micOn;
  final bool cameraOn;
  final bool remoteMicOn;
  final bool remoteCameraOn;

  /// When the call connected. Null until then.
  final DateTime? startedAt;

  /// Why the call ended, from the server or from this device.
  final String? endReason;

  /// A translation key for a problem to show once, such as a refused
  /// permission. The keys are under `calls.toasts`.
  final String? errorKey;

  bool get isActive => phase != CallPhase.idle && phase != CallPhase.ended;

  CallState copyWith({
    CallPhase? phase,
    String? callId,
    bool? micOn,
    bool? cameraOn,
    bool? remoteMicOn,
    bool? remoteCameraOn,
    DateTime? startedAt,
  }) {
    return CallState(
      phase: phase ?? this.phase,
      callId: callId ?? this.callId,
      peer: peer,
      mode: mode,
      micOn: micOn ?? this.micOn,
      cameraOn: cameraOn ?? this.cameraOn,
      remoteMicOn: remoteMicOn ?? this.remoteMicOn,
      remoteCameraOn: remoteCameraOn ?? this.remoteCameraOn,
      startedAt: startedAt ?? this.startedAt,
      endReason: endReason,
    );
  }
}
