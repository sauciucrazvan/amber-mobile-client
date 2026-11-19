import 'dart:async';

import 'package:amber_mobile_client/features/calls/bloc/call_cubit.dart';
import 'package:amber_mobile_client/features/calls/bloc/call_state.dart';
import 'package:amber_mobile_client/features/calls/data/call_models.dart';
import 'package:amber_mobile_client/features/calls/data/call_signaling.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_call_media.dart';

const _bob = CallPeer(username: 'bob', displayName: 'Bob');

/// Wires a cubit to a recording socket and a fake media. [incoming] is what
/// the server sends; [sent] is what the app sends.
class _Harness {
  _Harness() {
    cubit = CallCubit(
      signaling: CallSignaling(
        send: (message) {
          sent.add(message);
          return socketOpen;
        },
        incoming: incomingController.stream,
      ),
      media: media,
      summaryDuration: const Duration(milliseconds: 10),
    );
  }

  final incomingController = StreamController<Map<String, dynamic>>();
  final media = FakeCallMedia();
  final sent = <Map<String, Object?>>[];
  late final CallCubit cubit;
  bool socketOpen = true;

  /// Delivers a server message, then lets the cubit react.
  Future<void> receive(Map<String, dynamic> message) async {
    incomingController.add(message);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> dispose() async {
    await cubit.close();
    await incomingController.close();
  }
}

Map<String, dynamic> _ack(String callId) => {
  'type': 'ack',
  'event': 'call.invite',
  'payload': {'call_id': callId},
};

Map<String, dynamic> _state(
  String event, [
  Map<String, dynamic> extra = const {},
]) => {
  'type': 'call',
  'event': event,
  'payload': {'call_id': 'c1', ...extra},
};

Map<String, dynamic> _ringing() => {
  'type': 'call',
  'event': 'ringing',
  'payload': {
    'call_id': 'c1',
    'call_mode': 'video',
    'from': {'username': 'bob', 'display_name': 'Bob'},
  },
};

Map<String, dynamic> _webrtc(String event, Map<String, dynamic> data) => {
  'type': 'webrtc',
  'event': event,
  'payload': {'call_id': 'c1', 'data': data},
};

void main() {
  group('calling someone', () {
    test('invites, waits for the answer, then connects both ways', () async {
      final h = _Harness();
      addTearDown(h.dispose);

      await h.cubit.startCall(_bob, CallMode.video);
      expect(h.cubit.state.phase, CallPhase.outgoing);
      expect(h.sent.last, {
        'event': 'call.invite',
        'to': 'bob',
        'mode': 'video',
      });

      await h.receive(_ack('c1'));
      expect(h.cubit.state.callId, 'c1');

      await h.receive(_state('accepted'));
      expect(h.cubit.state.phase, CallPhase.connecting);
      expect(h.sent.last['event'], 'webrtc.offer');
      expect(h.sent.last['payload'], {'type': 'offer', 'sdp': 'offer-sdp'});

      await h.receive(
        _webrtc('answer', {'type': 'answer', 'sdp': 'their-answer'}),
      );
      expect(h.cubit.state.phase, CallPhase.inProgress);
      expect(h.cubit.state.startedAt, isNotNull);
      expect(h.media.calls, contains('apply:their-answer'));
    });

    test('a refused camera stops the call before anyone is rung', () async {
      final h = _Harness();
      addTearDown(h.dispose);
      h.media.allowDevices = false;

      await h.cubit.startCall(_bob, CallMode.video);

      expect(h.cubit.state.phase, CallPhase.idle);
      expect(h.cubit.state.errorKey, 'calls.errors.permission');
      expect(h.sent, isEmpty);
    });

    test(
      'cancelling before the server answers cancels once it has an id',
      () async {
        final h = _Harness();
        addTearDown(h.dispose);

        await h.cubit.startCall(_bob, CallMode.audio);
        h.cubit.cancelCall();
        expect(h.sent.where((m) => m['event'] == 'call.cancel'), isEmpty);

        await h.receive(_ack('c1'));

        expect(h.sent.last, {'event': 'call.cancel', 'call_id': 'c1'});
        expect(h.cubit.state.phase, CallPhase.ended);
        expect(h.cubit.state.endReason, 'canceled');
      },
    );

    test('a rejection ends the call and returns to idle', () async {
      final h = _Harness();
      addTearDown(h.dispose);
      await h.cubit.startCall(_bob, CallMode.video);
      await h.receive(_ack('c1'));

      await h.receive(_state('rejected'));
      expect(h.cubit.state.phase, CallPhase.ended);
      expect(h.cubit.state.endReason, 'rejected');

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(h.cubit.state.phase, CallPhase.idle);
    });
  });

  group('answering someone', () {
    test('rings, accepts, answers the offer and connects', () async {
      final h = _Harness();
      addTearDown(h.dispose);

      await h.receive(_ringing());
      expect(h.cubit.state.phase, CallPhase.incoming);
      expect(h.cubit.state.peer?.username, 'bob');

      await h.cubit.acceptCall();
      expect(h.sent.last, {'event': 'call.accept', 'call_id': 'c1'});
      expect(h.cubit.state.phase, CallPhase.connecting);

      await h.receive(
        _webrtc('offer', {'type': 'offer', 'sdp': 'their-offer'}),
      );
      expect(h.sent.last['event'], 'webrtc.answer');
      expect(h.cubit.state.phase, CallPhase.inProgress);
    });

    test('declining sends a reject and returns to idle', () async {
      final h = _Harness();
      addTearDown(h.dispose);
      await h.receive(_ringing());

      h.cubit.rejectCall();

      expect(h.sent.last, {'event': 'call.reject', 'call_id': 'c1'});
      expect(h.cubit.state.phase, CallPhase.idle);
    });

    test('a call cancelled by the caller is not answered', () async {
      final h = _Harness();
      addTearDown(h.dispose);
      await h.receive(_ringing());

      await h.receive(_state('canceled'));

      expect(h.cubit.state.phase, CallPhase.ended);
      expect(h.cubit.state.endReason, 'canceled');
    });
  });

  group('during a call', () {
    Future<_Harness> connected() async {
      final h = _Harness();
      await h.receive(_ringing());
      await h.cubit.acceptCall();
      await h.receive(_webrtc('offer', {'type': 'offer', 'sdp': 'o'}));
      return h;
    }

    test('ending sends end and shows the summary', () async {
      final h = await connected();
      addTearDown(h.dispose);

      h.cubit.endCall();

      expect(h.sent.last, {
        'event': 'call.end',
        'call_id': 'c1',
        'reason': 'ended',
      });
      expect(h.cubit.state.phase, CallPhase.ended);
      expect(h.media.calls.last, 'close');
    });

    test(
      'the other side ending the call does not send anything back',
      () async {
        final h = await connected();
        addTearDown(h.dispose);
        final sentBefore = h.sent.length;

        await h.receive(_state('ended', {'end_reason': 'hung-up'}));

        expect(h.sent.length, sentBefore);
        expect(h.cubit.state.endReason, 'hung-up');
      },
    );

    test('mute and camera changes reach the peer and the media', () async {
      final h = await connected();
      addTearDown(h.dispose);

      h.cubit.toggleMic();
      expect(h.cubit.state.micOn, isFalse);
      expect(h.media.calls, contains('mic:false'));
      expect(h.sent.last['event'], 'call.media-state');
      expect(h.sent.last['payload'], {
        'audio_enabled': false,
        'video_enabled': true,
      });

      h.cubit.toggleCamera();
      expect(h.cubit.state.cameraOn, isFalse);
      expect(h.sent.last['payload'], {
        'audio_enabled': false,
        'video_enabled': false,
      });
    });

    test("the peer's mute and camera state is shown", () async {
      final h = await connected();
      addTearDown(h.dispose);

      await h.receive({
        'type': 'webrtc',
        'event': 'media-state',
        'payload': {
          'call_id': 'c1',
          'data': {'audio_enabled': false, 'video_enabled': false},
        },
      });

      expect(h.cubit.state.remoteMicOn, isFalse);
      expect(h.cubit.state.remoteCameraOn, isFalse);
    });

    test('a server error resets the call and shows one message', () async {
      final h = await connected();
      addTearDown(h.dispose);

      await h.receive({
        'type': 'error',
        'code': 'call.invalid_state',
        'message': 'x',
      });

      expect(h.cubit.state.phase, CallPhase.idle);
      expect(h.cubit.state.errorKey, 'calls.errors.failed');
      expect(h.media.calls.last, 'close');
    });
  });

  test('a stray end for a call we are not in is ignored', () async {
    final h = _Harness();
    addTearDown(h.dispose);

    await h.receive(_state('ended'));

    expect(h.cubit.state.phase, CallPhase.idle);
  });
}
