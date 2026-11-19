# Calls: Media

Sources: `lib/features/calls/data/flutter_call_media.dart`, `lib/features/calls/data/call_media.dart`

The media is WebRTC through `flutter_webrtc`. `CallMedia` is the interface the call cubit drives. `FlutterCallMedia` is the real one, and the tests use a fake.

## Permissions

- The microphone is asked for every call, and the camera for video calls, at call time.
- A refusal stops the call before anyone is rung. The cubit shows `calls.errors.permission`.
- Android: `CAMERA`, `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`. The camera is optional, so phones without one can install the app.
- iOS: the camera and microphone usage strings are in `Info.plist`. `permission_handler` also needs preprocessor flags in the Podfile, which the project does not have yet. Add them when iOS is set up.

## Connection

- The offer and answer carry every ICE candidate. `FlutterCallMedia` waits for gathering to finish before it returns the SDP, with a five-second limit.
- STUN only, the same servers as the desktop's `simple-peer`. The backend has no TURN server.
- The camera is front-facing. Switching cameras and the speaker route come with the call screen.

## Streams

- `localStream` and `remoteStream` are value notifiers, so the call screen can show both when they change.
- Mute and camera toggles set `enabled` on the local tracks, and the cubit tells the peer through `call.media-state`.
