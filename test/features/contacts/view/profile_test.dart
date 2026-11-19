import 'package:amber_mobile_client/core/ui/amber_page.dart';
import 'package:amber_mobile_client/features/contacts/view/profile_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../support/auth_test_app.dart';
import '../../../support/fake_http_adapter.dart';

const _bobUser = {
  'id': 2,
  'username': 'bob',
  'full_name': 'Bob Ionescu',
  'avatar_url': null,
  'online': true,
  'last_active_at': null,
};

const _bobContact = {
  'user': _bobUser,
  'created_at': '2026-11-01T00:00:00+00:00',
  'last_action_at': '2026-11-18T00:00:00+00:00',
  'notifications': 0,
  'last_message': null,
};

const _bobProfile = {
  'id': 2,
  'username': 'bob',
  'full_name': 'Bob Ionescu',
  'avatar_url': null,
  'registered_at': '2026-01-02T00:00:00+00:00',
  'last_active_at': null,
  'bio': 'Coffee first.',
  'online': true,
  'verified': true,
  'disabled': false,
};

const _danBlocked = {
  'user': {'id': 4, 'username': 'dan'},
  'created_at': '2026-11-10T00:00:00+00:00',
};

/// Backend for a signed-in, verified user. Records every request so the
/// tests can check the calls made.
FakeHttpHandler _backend(
  List<RequestOptions> log, {
  List<Object> blocked = const [],
}) {
  return (options) {
    log.add(options);
    final path = options.path;
    if (path.endsWith('/auth/v1/login')) {
      return jsonResponse({
        'access_token': 'access-1',
        'refresh_token': 'refresh-1',
        'token_type': 'bearer',
      }, 200);
    }
    if (path.endsWith('/account/v1/me')) {
      return jsonResponse({
        'id': 1,
        'username': 'ana',
        'full_name': 'Ana Pop',
        'verified': true,
      }, 200);
    }
    if (path.endsWith('/contacts/v1/list')) {
      return jsonResponse([_bobContact], 200);
    }
    if (path.endsWith('/contacts/v1/requests')) return jsonResponse([], 200);
    if (path.endsWith('/contacts/v1/profile/bob')) {
      return jsonResponse(_bobProfile, 200);
    }
    if (path.endsWith('/chats/v1/direct/2')) {
      return jsonResponse({
        'id': 'c-1',
        'type': 'direct',
        'direct_pair': 'pair',
        'created_at': '2026-11-01T00:00:00+00:00',
        'notifications': 0,
      }, 200);
    }
    if (path.contains('/chats/v1/c-1/messages')) {
      return jsonResponse([], 200);
    }
    if (path.endsWith('/contacts/v1/blocked')) {
      return jsonResponse(blocked, 200);
    }
    return jsonResponse({'message': 'ok'}, 200);
  };
}

Future<void> _signIn(WidgetTester tester, FakeHttpHandler backend) async {
  final cubit = await pumpAuthApp(tester, backend);
  await tester.runAsync(() => cubit.login('ana', 'Secret123'));
  await settleRequests(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
  await settleRequests(tester);
}

/// Opens Bob's profile through the chat: tap the contact, then the header.
Future<void> _openProfile(WidgetTester tester) async {
  await _tap(tester, find.text('Bob Ionescu'));
  await _tap(
    tester,
    find.descendant(
      of: find.byType(AppBar),
      matching: find.text('Bob Ionescu'),
    ),
  );
}

void main() {
  testWidgets('tapping a contact opens the profile with bio and dates', (
    tester,
  ) async {
    final log = <RequestOptions>[];
    await _signIn(tester, _backend(log));

    await _openProfile(tester);

    expect(find.byType(ContactProfileScreen), findsOneWidget);
    expect(find.byType(AmberPage), findsOneWidget);
    expect(find.byType(ShadDialog), findsNothing);
    expect(find.text('Coffee first.'), findsOneWidget);
    expect(find.text('Member since'), findsOneWidget);
    expect(find.text('January 2026'), findsOneWidget);
    expect(find.text('now'), findsOneWidget);
  });

  testWidgets('blocking asks first, calls the API and removes the contact', (
    tester,
  ) async {
    final log = <RequestOptions>[];
    await _signIn(tester, _backend(log));
    await _openProfile(tester);

    await _tap(tester, find.text('Block'));
    expect(find.byType(ShadDialog), findsOneWidget);
    await _tap(
      tester,
      find.descendant(
        of: find.byType(ShadDialog).last,
        matching: find.text('Block'),
      ),
    );

    final block = log.lastWhere((r) => r.method == 'PUT');
    expect(block.path, endsWith('/contacts/v1/block'));
    expect(block.data, {'username': 'bob'});
    expect(find.byType(ContactProfileScreen), findsNothing);
    expect(find.text('Bob Ionescu'), findsNothing);
  });

  testWidgets('cancelling the block confirmation does nothing', (tester) async {
    final log = <RequestOptions>[];
    await _signIn(tester, _backend(log));
    await _openProfile(tester);

    await _tap(tester, find.text('Block'));
    await _tap(tester, find.text('Cancel'));

    expect(log.where((r) => r.method == 'PUT'), isEmpty);
    expect(find.byType(ContactProfileScreen), findsOneWidget);
  });

  testWidgets('blocked accounts can be unblocked', (tester) async {
    final log = <RequestOptions>[];
    await _signIn(tester, _backend(log, blocked: [_danBlocked]));

    await _tap(tester, find.byKey(const ValueKey('nav-settings')));
    await _tap(tester, find.byKey(const ValueKey('open-blocked')));
    expect(find.text('@dan'), findsOneWidget);

    await _tap(tester, find.text('Unblock'));

    final unblock = log.lastWhere((r) => r.method == 'DELETE');
    expect(unblock.path, endsWith('/contacts/v1/unblock'));
    expect(unblock.data, {'username': 'dan'});
  });
}
