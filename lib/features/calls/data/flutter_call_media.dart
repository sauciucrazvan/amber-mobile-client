import 'dart:async';

import 'package:amber_mobile_client/features/calls/data/call_media.dart';
import 'package:amber_mobile_client/features/calls/data/call_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

/// The STUN servers the desktop's `simple-peer` uses by default. The backend
/// has no TURN server, so calls behind a strict NAT can fail.
const _iceConfiguration = {
  'iceServers': [
    {
      'urls': [
        'stun:stun.l.google.com:19302',
        'stun:global.stun.twilio.com:3478',
      ],
    },
  ],
};

/// The camera, microphone and WebRTC connection for one call.
class FlutterCallMedia implements CallMedia {
  /// What we send. Null until [prepare] succeeds and after [close].
  final ValueNotifier<MediaStream?> localStream = ValueNotifier(null);

  /// What the peer sends, once their track arrives.
  final ValueNotifier<MediaStream?> remoteStream = ValueNotifier(null);

  RTCPeerConnection? _peer;

  @override
  Future<bool> prepare(CallMode mode) async {
    if (!(await Permission.microphone.request()).isGranted) return false;
    if (mode == CallMode.video &&
        !(await Permission.camera.request()).isGranted) {
      return false;
    }

    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': mode == CallMode.video ? {'facingMode': 'user'} : false,
    });
    localStream.value = stream;

    final peer = await createPeerConnection(_iceConfiguration);
    peer.onTrack = (event) {
      if (event.streams.isNotEmpty) remoteStream.value = event.streams.first;
    };
    for (final track in stream.getTracks()) {
      await peer.addTrack(track, stream);
    }
    _peer = peer;
    return true;
  }

  @override
  Future<String> createOffer() async {
    final peer = _peer!;
    await peer.setLocalDescription(await peer.createOffer({}));
    await _waitForCandidates(peer);
    return (await peer.getLocalDescription())!.sdp!;
  }

  @override
  Future<String> answer(String offerSdp) async {
    final peer = _peer!;
    await peer.setRemoteDescription(RTCSessionDescription(offerSdp, 'offer'));
    await peer.setLocalDescription(await peer.createAnswer({}));
    await _waitForCandidates(peer);
    return (await peer.getLocalDescription())!.sdp!;
  }

  @override
  Future<void> applyAnswer(String answerSdp) async {
    await _peer!.setRemoteDescription(
      RTCSessionDescription(answerSdp, 'answer'),
    );
  }

  @override
  void setMicEnabled(bool enabled) {
    for (final track in localStream.value?.getAudioTracks() ?? const []) {
      track.enabled = enabled;
    }
  }

  @override
  void setCameraEnabled(bool enabled) {
    for (final track in localStream.value?.getVideoTracks() ?? const []) {
      track.enabled = enabled;
    }
  }

  @override
  void switchCamera() {
    final track = localStream.value?.getVideoTracks().firstOrNull;
    if (track != null) unawaited(Helper.switchCamera(track));
  }

  @override
  void setSpeakerOn(bool enabled) {
    unawaited(Helper.setSpeakerphoneOn(enabled));
  }

  /// Frees the streams. Call after [close].
  void dispose() {
    localStream.dispose();
    remoteStream.dispose();
  }

  @override
  Future<void> close() async {
    final stream = localStream.value;
    localStream.value = null;
    remoteStream.value = null;
    for (final track in stream?.getTracks() ?? const []) {
      await track.stop();
    }
    await stream?.dispose();
    await _peer?.close();
    _peer = null;
  }

  /// The offer or answer is sent whole, so wait until every ICE candidate is
  /// in it. A timeout still sends what has been gathered.
  Future<void> _waitForCandidates(RTCPeerConnection peer) async {
    if (peer.iceGatheringState ==
        RTCIceGatheringState.RTCIceGatheringStateComplete) {
      return;
    }
    final done = Completer<void>();
    peer.onIceGatheringState = (state) {
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete &&
          !done.isCompleted) {
        done.complete();
      }
    };
    await done.future.timeout(const Duration(seconds: 5), onTimeout: () {});
  }
}
