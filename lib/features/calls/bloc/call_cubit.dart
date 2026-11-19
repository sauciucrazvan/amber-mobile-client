import 'dart:async';

import 'package:amber_mobile_client/features/calls/bloc/call_state.dart';
import 'package:amber_mobile_client/features/calls/data/call_media.dart';
import 'package:amber_mobile_client/features/calls/data/call_models.dart';
import 'package:amber_mobile_client/features/calls/data/call_signal.dart';
import 'package:amber_mobile_client/features/calls/data/call_signaling.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Runs one call at a time: invite or answer, the offer and answer exchange,
/// mute and camera state, and the end. Follows the desktop's call flow.
class CallCubit extends Cubit<CallState> {
  CallCubit({
    required this.signaling,
    required this.media,
    this.summaryDuration = const Duration(seconds: 4),
  }) : super(const CallState()) {
    _subscription = signaling.signals.listen(_onSignal);
  }

  final CallSignaling signaling;
  final CallMedia media;

  /// How long an ended call stays on screen before the app returns to idle.
  final Duration summaryDuration;

  late final StreamSubscription<CallSignal> _subscription;
  Timer? _summaryTimer;

  /// Set when the user cancels before the server has given the call its id.
  bool _cancelRequested = false;

  /// Invites [peer]. Asks for the devices first, so a refusal stops the call
  /// before anyone is rung.
  Future<void> startCall(CallPeer peer, CallMode mode) async {
    if (state.phase != CallPhase.idle) return;
    final ready = await media.prepare(mode);
    if (state.phase != CallPhase.idle) return;
    if (!ready) {
      await media.close();
      emit(const CallState(errorKey: 'calls.errors.permission'));
      return;
    }
    if (!signaling.invite(peer.username, mode)) {
      await media.close();
      emit(const CallState(errorKey: 'calls.errors.unreachable'));
      return;
    }
    emit(CallState(phase: CallPhase.outgoing, peer: peer, mode: mode));
  }

  /// Answers the incoming call.
  Future<void> acceptCall() async {
    final current = state;
    if (current.phase != CallPhase.incoming) return;
    final callId = current.callId!;
    final ready = await media.prepare(current.mode);
    if (state.callId != callId || state.phase != CallPhase.incoming) return;
    if (!ready) {
      signaling.reject(callId);
      await media.close();
      emit(const CallState(errorKey: 'calls.errors.permission'));
      return;
    }
    if (!signaling.accept(callId)) {
      await media.close();
      emit(const CallState(errorKey: 'calls.errors.unreachable'));
      return;
    }
    emit(state.copyWith(phase: CallPhase.connecting));
  }

  /// Declines the incoming call.
  void rejectCall() {
    final current = state;
    if (current.phase != CallPhase.incoming) return;
    signaling.reject(current.callId!);
    emit(const CallState());
  }

  /// Hangs up before the call is answered.
  void cancelCall() {
    if (state.phase != CallPhase.outgoing) return;
    final callId = state.callId;
    if (callId == null) {
      _cancelRequested = true;
      return;
    }
    signaling.cancel(callId);
    _finish('canceled');
  }

  /// Ends a call that is connecting or in progress.
  void endCall() {
    if (!state.isActive || state.phase == CallPhase.incoming) return;
    final callId = state.callId;
    if (callId != null) signaling.end(callId);
    _finish('ended');
  }

  void toggleMic() {
    if (state.phase != CallPhase.inProgress &&
        state.phase != CallPhase.connecting) {
      return;
    }
    final micOn = !state.micOn;
    media.setMicEnabled(micOn);
    _shareMediaState(micOn: micOn, cameraOn: state.cameraOn);
    emit(state.copyWith(micOn: micOn));
  }

  void toggleCamera() {
    if (state.mode != CallMode.video) return;
    if (state.phase != CallPhase.inProgress &&
        state.phase != CallPhase.connecting) {
      return;
    }
    final cameraOn = !state.cameraOn;
    media.setCameraEnabled(cameraOn);
    _shareMediaState(micOn: state.micOn, cameraOn: cameraOn);
    emit(state.copyWith(cameraOn: cameraOn));
  }

  /// Clears the error, so the UI can show it once.
  void clearError() {
    if (state.errorKey != null) emit(const CallState());
  }

  void _shareMediaState({required bool micOn, required bool cameraOn}) {
    final callId = state.callId;
    if (callId == null) return;
    signaling.sendMediaState(
      callId,
      audioEnabled: micOn,
      videoEnabled: cameraOn,
    );
  }

  Future<void> _onSignal(CallSignal signal) async {
    switch (signal) {
      case CallInviteAck(:final callId):
        if (state.phase != CallPhase.outgoing || state.callId != null) return;
        emit(state.copyWith(callId: callId));
        if (_cancelRequested) {
          _cancelRequested = false;
          cancelCall();
        }
      case CallRinging(:final callId, :final peer, :final mode):
        if (state.phase != CallPhase.idle) return;
        emit(
          CallState(
            phase: CallPhase.incoming,
            callId: callId,
            peer: peer,
            mode: mode,
          ),
        );
      case CallAccepted(:final callId):
        if (!_isCurrent(callId) || state.phase != CallPhase.outgoing) return;
        emit(state.copyWith(phase: CallPhase.connecting));
        final offer = await media.createOffer();
        if (!_isCurrent(callId)) return;
        signaling.sendOffer(callId, offer);
      case CallOffer(:final callId, :final sdp):
        if (!_isCurrent(callId) || state.phase != CallPhase.connecting) return;
        final answer = await media.answer(sdp);
        if (!_isCurrent(callId)) return;
        signaling.sendAnswer(callId, answer);
        _connected();
      case CallAnswer(:final callId, :final sdp):
        if (!_isCurrent(callId) || state.phase != CallPhase.connecting) return;
        await media.applyAnswer(sdp);
        if (!_isCurrent(callId)) return;
        _connected();
      case CallMediaState(
        :final callId,
        :final audioEnabled,
        :final videoEnabled,
      ):
        if (!_isCurrent(callId)) return;
        emit(
          state.copyWith(
            remoteMicOn: audioEnabled,
            remoteCameraOn: videoEnabled,
          ),
        );
      case CallRejected(:final callId):
        if (_isCurrent(callId) && state.isActive) _finish('rejected');
      case CallCanceled(:final callId):
        if (_isCurrent(callId) && state.isActive) _finish('canceled');
      case CallEnded(:final callId, :final reason):
        if (_isCurrent(callId) && state.isActive) _finish(reason ?? 'ended');
      case CallMissed(:final callId):
        if (_isCurrent(callId) && state.isActive) _finish('missed');
      case CallFailed(:final callId):
        if (_isCurrent(callId) && state.isActive) _finish('failed');
      case CallTerminatedElsewhere(:final callId):
        if (_isCurrent(callId) && state.isActive) _finish('answered-elsewhere');
      case CallError():
        if (state.phase == CallPhase.idle || state.phase == CallPhase.ended) {
          return;
        }
        await media.close();
        emit(const CallState(errorKey: 'calls.errors.failed'));
    }
  }

  bool _isCurrent(String callId) => state.callId == callId;

  void _connected() {
    emit(
      state.copyWith(phase: CallPhase.inProgress, startedAt: DateTime.now()),
    );
  }

  /// Ends the call on this device and shows the summary for a moment.
  void _finish(String reason) {
    _summaryTimer?.cancel();
    final current = state;
    unawaited(media.close());
    emit(
      CallState(
        phase: CallPhase.ended,
        callId: current.callId,
        peer: current.peer,
        mode: current.mode,
        startedAt: current.startedAt,
        endReason: reason,
      ),
    );
    _summaryTimer = Timer(summaryDuration, () {
      if (state.phase == CallPhase.ended) emit(const CallState());
    });
  }

  @override
  Future<void> close() async {
    _summaryTimer?.cancel();
    await _subscription.cancel();
    await media.close();
    return super.close();
  }
}
