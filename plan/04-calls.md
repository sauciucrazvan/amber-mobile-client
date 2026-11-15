# 04 - Calls

Audio and video calls between two contacts, using WebRTC. Signaling goes through the same WebSocket as everything else.

## Screens

- Outgoing call (ringing, cancel)
- Incoming call (accept, reject)
- In-progress call (remote video, local preview, mute, camera toggle, end call, duration)
- Call ended (summary, return to chat)

The call UI sits on top of the app, so it stays visible if the user navigates elsewhere.

## Signaling Events

Over the WebSocket:

- `call.invite`: start a call (carries `call_id` and mode, `audio` or `video`)
- `call.accept` / `call.accepted`: answer and confirmation
- `call.reject`: decline
- `call.cancel`: caller hangs up before answer
- `call.end`: either side ends the call
- `call.media-state`: mute and camera state, shared with the peer
- `call.terminated_elsewhere`: the same user answered on another device
- `call.error`: show a toast and reset the call state
- `webrtc.ice-candidate`: ICE candidates
- SDP offer and answer are exchanged as signal payloads (`offer`, `answer`)

## Media

- Use a WebRTC library for Flutter (for example `flutter_webrtc`) for the peer connection and media tracks. Confirm the choice before implementing.
- Permissions: microphone for audio calls, camera for video calls. Request them at call time with a clear reason.
- Device selection: the desktop lets the user pick a microphone, camera, and speaker. On mobile, support switching between front and back cameras and the speaker or earpiece route.

## Platform Integration

- The desktop has no OS-level call UI. On mobile, use CallKit (iOS) and ConnectionService (Android) so incoming calls ring like phone calls. This needs native setup and is a separate PR within this feature.
- Push notifications for incoming calls when the app is in the background. The backend must support this; confirm before building it.

## Open Decisions

- Whether to ship the CallKit and push work in the first PR or as a follow-up.
- TURN server configuration. Confirm which STUN and TURN servers the backend expects. The desktop code does not show this, so it needs checking against the backend.

## Acceptance

- Audio and video calls connect in both directions between two devices.
- Mute, camera toggle, reject, cancel, and end update the other side.
- A call that ends unexpectedly returns the UI to a clean state.
