# Calls: Screens

Sources: `lib/features/calls/view/`, `lib/features/chat/view/conversation_header.dart`, `lib/app.dart`

## Where the call lives

`CallsScope` creates the call cubit and the WebRTC media once, above the navigator. `CallOverlay` sits in the app's `MaterialApp` builder, so the call screen covers every page while a call is going on. Leaving the chat does not end the call.

## Starting a call

The chat header has an audio button and a video button, after the contact's name. They are disabled while another call is going on. If the contact is offline, a toast says so, as on the desktop, and no call starts.

## Call screen

`CallScreen` shows the phase:

| Phase | Shows | Controls |
|-------|-------|----------|
| Outgoing | The contact's name and avatar, "Ringing" | Hang up |
| Incoming | "Incoming call" | Decline, Answer |
| Connecting | "Connecting..." | Mute, camera (video only), switch camera (video only), speaker, end |
| In progress | The duration, counting up each second | The same as connecting |
| Ended | The reason: Rejected, Missed, Failed, Canceled, Ended, or Answered on another device | None. Returns to idle after four seconds |

For a video call that is connected and has the peer's camera on, the peer's video fills the screen, and our camera shows in a small preview in the top-right corner.

Problems, such as a refused microphone or the server refusing a call, show as a toast through `calls.toasts.*`, and the call returns to idle.

## Strings

All text comes from the desktop's `calls` keys. Added for mobile: `calls.status.connecting`, `calls.status.canceled` and `calls.status.answeredElsewhere`.
