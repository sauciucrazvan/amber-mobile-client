import 'package:amber_mobile_client/features/calls/data/call_models.dart';
import 'package:amber_mobile_client/features/calls/data/call_signal.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _ringing({String mode = 'audio'}) => {
  'type': 'call',
  'event': 'ringing',
  'payload': {
    'call_id': 'c1',
    'mode': mode,
    'call_mode': mode,
    'from': {'username': 'bob', 'display_name': 'Bob', 'avatar_url': null},
  },
};

void main() {
  test('a ringing call carries the caller and the mode', () {
    final signal = parseCallSignal(_ringing()) as CallRinging;

    expect(signal.callId, 'c1');
    expect(signal.mode, CallMode.audio);
    expect(signal.peer.username, 'bob');
    expect(signal.peer.displayName, 'Bob');
  });

  test('an unknown mode is a video call, as on the backend', () {
    final signal = parseCallSignal(_ringing(mode: 'hologram')) as CallRinging;

    expect(signal.mode, CallMode.video);
  });

  test('the invite acknowledgement gives the call id', () {
    final signal = parseCallSignal({
      'type': 'ack',
      'event': 'call.invite',
      'payload': {'call_id': 'c1', 'status': 'ringing', 'call_mode': 'video'},
    });

    expect(signal, isA<CallInviteAck>());
    expect(signal!.callId, 'c1');
  });

  test('the server call states map to their signals', () {
    CallSignal? parse(String event, [Map<String, dynamic> extra = const {}]) {
      return parseCallSignal({
        'type': 'call',
        'event': event,
        'payload': {'call_id': 'c1', ...extra},
      });
    }

    expect(parse('accepted'), isA<CallAccepted>());
    expect(parse('call.accepted'), isA<CallAccepted>());
    expect(parse('rejected'), isA<CallRejected>());
    expect(parse('cancel'), isA<CallCanceled>());
    expect(parse('canceled'), isA<CallCanceled>());
    expect(parse('missed'), isA<CallMissed>());
    expect(parse('failed'), isA<CallFailed>());
    expect(parse('call.terminated_elsewhere'), isA<CallTerminatedElsewhere>());
    expect(
      (parse('ended', {'end_reason': 'hung-up'}) as CallEnded).reason,
      'hung-up',
    );
    expect(parse('initiated'), isNull, reason: 'the caller already knows');
  });

  test('offers, answers and media state come from the data field', () {
    final offer = parseCallSignal({
      'type': 'webrtc',
      'event': 'offer',
      'payload': {
        'call_id': 'c1',
        'from_username': 'bob',
        'data': {'type': 'offer', 'sdp': 'v=0'},
      },
    }) as CallOffer;
    expect(offer.sdp, 'v=0');

    final media = parseCallSignal({
      'type': 'webrtc',
      'event': 'media-state',
      'payload': {
        'call_id': 'c1',
        'data': {'audio_enabled': false, 'video_enabled': true},
      },
    }) as CallMediaState;
    expect(media.audioEnabled, isFalse);
    expect(media.videoEnabled, isTrue);
  });

  test('only call and signalling errors are ours', () {
    expect(
      parseCallSignal({
        'type': 'error',
        'code': 'call.invalid_state',
        'message': 'x',
      }),
      isA<CallError>(),
    );
    expect(
      parseCallSignal({
        'type': 'error',
        'code': 'chat.not_found',
        'message': 'x',
      }),
      isNull,
    );
  });
}
