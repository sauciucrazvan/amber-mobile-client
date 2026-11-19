# Calls: Signaling and state

Sources: `lib/features/calls/data/`, `lib/features/calls/bloc/`

Calls use the same WebSocket as everything else. This part is the signalling and the call state machine. The media (WebRTC) and the screens come in later steps.

## Messages we send

Each message is a JSON object with an `event` field. Most fields sit at the top level. SDP data goes under `payload`, as the backend expects.

| Event | Fields | Sent by `CallSignaling` |
|-------|--------|--------------------------|
| `call.invite` | `to` (username), `mode` (`audio` or `video`) | `invite` |
| `call.accept` | `call_id` | `accept` |
| `call.reject` | `call_id` | `reject` |
| `call.cancel` | `call_id` | `cancel` |
| `call.end` | `call_id`, `reason` | `end` |
| `webrtc.offer` / `webrtc.answer` | `call_id`, `payload: {type, sdp}` | `sendOffer`, `sendAnswer` |
| `call.media-state` | `call_id`, `payload: {audio_enabled, video_enabled}` | `sendMediaState` |

The desktop sends ICE candidates as `webrtc.ice-candidate`, but it builds its peer connection with trickle off. The offer and answer carry every candidate, so the mobile client sends none.

## Messages we receive

`parseCallSignal` turns each one into a `CallSignal`. Anything else returns null.

| Server message | Signal |
|----------------|--------|
| `ack` with `event: call.invite` | `CallInviteAck` (gives the `call_id`) |
| `call` / `ringing` | `CallRinging` (caller in `from`, mode in `call_mode`) |
| `call` / `accepted` or `call.accepted` | `CallAccepted` |
| `call` / `rejected` | `CallRejected` |
| `call` / `cancel` or `canceled` | `CallCanceled` |
| `call` / `ended` | `CallEnded` (reason in `end_reason`) |
| `call` / `missed` | `CallMissed` |
| `call` / `failed` | `CallFailed` |
| `call` / `call.terminated_elsewhere` | `CallTerminatedElsewhere` |
| `webrtc` / `offer`, `answer`, `media-state` | `CallOffer`, `CallAnswer`, `CallMediaState` |
| `error` with a `call.` or `signal.` code | `CallError` |

`call` / `initiated` is ignored, since the caller already knows.

## Call flow

Caller:

1. `startCall` asks for the devices. A refusal stops the call here.
2. Sends `call.invite`. The `ack` gives the call id.
3. On `accepted`, creates the offer and sends it.
4. On `answer`, applies it. The call is in progress.

Callee:

1. `ringing` shows the incoming call.
2. `acceptCall` asks for the devices, then sends `call.accept`.
3. On `offer`, answers and sends the answer. The call is in progress.

Ending: `endCall` sends `call.end`. The other side gets `ended`. A call that is already over ignores later messages for it, so a server echo does not end it twice. The summary stays for four seconds, then the state returns to idle.

## Errors

A `CallError` resets the call and sets `calls.errors.failed` once, so the UI can show it as a toast.

## Open decisions

- The media uses `flutter_webrtc`, the library the plan names. It goes in the next step.
- STUN only, the same default servers that `simple-peer` uses on the desktop: `stun:stun.l.google.com:19302` and `stun:global.stun.twilio.com:3478`. The backend has no TURN configuration, so calls behind strict NAT may fail until one exists.
- CallKit and push notifications are a separate PR, as the plan says.
