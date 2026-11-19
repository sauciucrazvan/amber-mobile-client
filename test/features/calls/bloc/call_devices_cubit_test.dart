import 'package:amber_mobile_client/features/calls/bloc/call_devices_cubit.dart';
import 'package:amber_mobile_client/features/calls/data/call_devices.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the defaults are the front camera and the speaker', () async {
    final cubit = CallDevicesCubit();
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.camera, CameraChoice.front);
    expect(cubit.state.audioOutput, AudioOutput.speaker);
  });

  test('choices are saved and read back on the next launch', () async {
    final first = CallDevicesCubit();
    addTearDown(first.close);
    await first.setCamera(CameraChoice.back);
    await first.setAudioOutput(AudioOutput.earpiece);

    final second = CallDevicesCubit();
    addTearDown(second.close);
    await second.load();

    expect(second.state.camera, CameraChoice.back);
    expect(second.state.audioOutput, AudioOutput.earpiece);
  });
}
