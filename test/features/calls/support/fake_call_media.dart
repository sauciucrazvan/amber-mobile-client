import 'package:amber_mobile_client/features/calls/data/call_media.dart';
import 'package:amber_mobile_client/features/calls/data/call_models.dart';

/// Records what the cubit asks of the media, instead of using real devices.
class FakeCallMedia implements CallMedia {
  /// False to act as if the user refused the camera or microphone.
  bool allowDevices = true;

  final calls = <String>[];

  @override
  Future<bool> prepare(CallMode mode) async {
    calls.add('prepare:${mode.name}');
    return allowDevices;
  }

  @override
  Future<String> createOffer() async {
    calls.add('offer');
    return 'offer-sdp';
  }

  @override
  Future<String> answer(String offerSdp) async {
    calls.add('answer:$offerSdp');
    return 'answer-sdp';
  }

  @override
  Future<void> applyAnswer(String answerSdp) async {
    calls.add('apply:$answerSdp');
  }

  @override
  void setMicEnabled(bool enabled) => calls.add('mic:$enabled');

  @override
  void setCameraEnabled(bool enabled) => calls.add('camera:$enabled');

  @override
  void switchCamera() => calls.add('switch-camera');

  @override
  void setSpeakerOn(bool enabled) => calls.add('speaker:$enabled');

  @override
  Future<void> close() async => calls.add('close');
}
