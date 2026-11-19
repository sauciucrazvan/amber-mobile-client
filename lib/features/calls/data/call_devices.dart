/// Which camera a call starts with.
enum CameraChoice {
  front,
  back;

  static CameraChoice parse(String? value) =>
      value == 'back' ? CameraChoice.back : CameraChoice.front;
}

/// Where a call's sound goes: the loudspeaker, or the earpiece.
enum AudioOutput {
  speaker,
  earpiece;

  static AudioOutput parse(String? value) =>
      value == 'earpiece' ? AudioOutput.earpiece : AudioOutput.speaker;
}

/// The device choices the next call uses. They are per device.
class CallDevices {
  const CallDevices({
    this.camera = CameraChoice.front,
    this.audioOutput = AudioOutput.speaker,
  });

  final CameraChoice camera;
  final AudioOutput audioOutput;

  CallDevices copyWith({CameraChoice? camera, AudioOutput? audioOutput}) {
    return CallDevices(
      camera: camera ?? this.camera,
      audioOutput: audioOutput ?? this.audioOutput,
    );
  }
}
