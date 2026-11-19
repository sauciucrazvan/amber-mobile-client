import 'package:amber_mobile_client/features/calls/data/call_models.dart';

/// The camera, microphone and peer connection for one call. The cubit drives
/// it, so the call logic can be tested without real devices.
abstract class CallMedia {
  /// Asks for the microphone, and the camera for video calls. False when
  /// the user refuses.
  Future<bool> prepare(CallMode mode);

  /// Creates the caller's offer. The SDP is complete, so no separate ICE
  /// messages are needed.
  Future<String> createOffer();

  /// Applies the callee's offer and returns the answer SDP.
  Future<String> answer(String offerSdp);

  /// Applies the callee's answer on the caller's side.
  Future<void> applyAnswer(String answerSdp);

  void setMicEnabled(bool enabled);

  void setCameraEnabled(bool enabled);

  /// Switches between the front and back camera.
  void switchCamera();

  /// Routes the sound to the loudspeaker, or to the earpiece.
  void setSpeakerOn(bool enabled);

  /// Stops the tracks and closes the peer connection.
  Future<void> close();
}
