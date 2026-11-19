import 'dart:async';

import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/session/session_store.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/auth/data/auth_api.dart';
import 'package:amber_mobile_client/features/calls/bloc/call_cubit.dart';
import 'package:amber_mobile_client/features/calls/data/call_models.dart';
import 'package:amber_mobile_client/features/calls/data/call_signaling.dart';
import 'package:amber_mobile_client/features/calls/data/flutter_call_media.dart';
import 'package:amber_mobile_client/features/calls/view/call_overlay.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../support/memory_key_value_storage.dart';
import '../support/fake_call_media.dart';

class _Harness {
  _Harness() {
    cubit = CallCubit(
      signaling: CallSignaling(
        send: (message) {
          sent.add(message);
          return true;
        },
        incoming: incoming.stream,
      ),
      media: media,
    );
  }

  final incoming = StreamController<Map<String, dynamic>>();
  final media = FakeCallMedia();
  final sent = <Map<String, Object?>>[];
  late final CallCubit cubit;

  Future<void> close() async {
    await cubit.close();
    await incoming.close();
  }
}

Map<String, dynamic> _ringing() => {
  'type': 'call',
  'event': 'ringing',
  'payload': {
    'call_id': 'c1',
    'call_mode': 'audio',
    'from': {'username': 'bob', 'display_name': 'Bob Ionescu'},
  },
};

Future<void> _pump(WidgetTester tester, _Harness h) async {
  final localizations = (await tester.runAsync(
    () => AppLocalizations.load('en'),
  ))!;
  final client = ApiClient(sessionStore: SessionStore(MemoryKeyValueStorage()));
  final auth = AuthCubit(
    api: AuthApi(client),
    client: client,
    connectRealtime: () async {},
    disconnectRealtime: () async {},
  );
  addTearDown(auth.close);
  await tester.pumpWidget(
    AppLocalizationsScope(
      localizations: localizations,
      child: RepositoryProvider<FlutterCallMedia>.value(
        value: FlutterCallMedia(),
        child: BlocProvider<AuthCubit>.value(
          value: auth,
          child: BlocProvider<CallCubit>.value(
            value: h.cubit,
            child: ShadApp.custom(
              appBuilder: (_) => MaterialApp(
                builder: (context, child) =>
                    ShadToaster(child: CallOverlay(child: child!)),
                home: const Scaffold(body: Text('home')),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Lets a server message through the stream and the cubit.
Future<void> _receive(
  WidgetTester tester,
  _Harness h,
  Map<String, dynamic> message,
) async {
  h.incoming.add(message);
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}

void main() {
  testWidgets('a ringing call shows Answer and Decline', (tester) async {
    final h = _Harness();
    addTearDown(h.close);
    await _pump(tester, h);

    await _receive(tester, h, _ringing());

    expect(find.text('Bob Ionescu'), findsOneWidget);
    expect(find.text('Incoming call'), findsOneWidget);
    expect(find.byKey(const ValueKey('call-answer')), findsOneWidget);
    expect(find.byKey(const ValueKey('call-decline')), findsOneWidget);
  });

  testWidgets('answering sends the accept and shows connecting', (
    tester,
  ) async {
    final h = _Harness();
    addTearDown(h.close);
    await _pump(tester, h);
    await _receive(tester, h, _ringing());

    await tester.tap(find.byKey(const ValueKey('call-answer')));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(h.sent.last, {'event': 'call.accept', 'call_id': 'c1'});
    expect(find.text('Connecting...'), findsOneWidget);
  });

  testWidgets('calling shows Ringing, and hanging up sends the cancel', (
    tester,
  ) async {
    final h = _Harness();
    addTearDown(h.close);
    await _pump(tester, h);

    await tester.runAsync(
      () => h.cubit.startCall(
        const CallPeer(username: 'bob', displayName: 'Bob Ionescu'),
        CallMode.audio,
      ),
    );
    await tester.pump();

    expect(find.text('Ringing'), findsOneWidget);
    expect(find.byKey(const ValueKey('call-cancel')), findsOneWidget);

    await _receive(tester, h, {
      'type': 'ack',
      'event': 'call.invite',
      'payload': {'call_id': 'c1'},
    });
    await tester.tap(find.byKey(const ValueKey('call-cancel')));
    await tester.pump();

    expect(h.sent.last, {'event': 'call.cancel', 'call_id': 'c1'});
  });

  testWidgets('a refused microphone shows a toast and no call screen', (
    tester,
  ) async {
    final h = _Harness();
    addTearDown(h.close);
    h.media.allowDevices = false;
    await _pump(tester, h);

    await tester.runAsync(
      () => h.cubit.startCall(
        const CallPeer(username: 'bob', displayName: 'Bob Ionescu'),
        CallMode.audio,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Could not access camera/microphone.'), findsOneWidget);
    expect(find.byKey(const ValueKey('call-cancel')), findsNothing);
    expect(h.sent, isEmpty);
  });
}
