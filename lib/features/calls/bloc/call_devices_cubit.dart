import 'package:amber_mobile_client/features/calls/data/call_devices.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the camera and audio output for calls, and saves them per device.
/// The next call uses whatever is set here.
class CallDevicesCubit extends Cubit<CallDevices> {
  CallDevicesCubit() : super(const CallDevices());

  static const _cameraKey = 'amber.callCamera';
  static const _audioOutputKey = 'amber.callAudioOutput';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    emit(
      CallDevices(
        camera: CameraChoice.parse(prefs.getString(_cameraKey)),
        audioOutput: AudioOutput.parse(prefs.getString(_audioOutputKey)),
      ),
    );
  }

  Future<void> setCamera(CameraChoice camera) async {
    emit(state.copyWith(camera: camera));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cameraKey, camera.name);
  }

  Future<void> setAudioOutput(AudioOutput output) async {
    emit(state.copyWith(audioOutput: output));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_audioOutputKey, output.name);
  }
}
