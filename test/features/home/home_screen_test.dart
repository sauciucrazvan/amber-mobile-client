import 'package:amber_mobile_client/features/contacts/view/contact_avatar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/auth_test_app.dart';
import '../../support/fake_http_adapter.dart';

const _bob = {
  'user': {
    'id': 2,
    'username': 'bob',
    'full_name': 'Bob Ionescu',
    'avatar_url': null,
    'online': true,
    'last_active_at': null,
  },
  'created_at': '2026-11-01T00:00:00+00:00',
  'last_action_at': '2026-11-18T00:00:00+00:00',
  'notifications': 2,
  'last_message': {
    'sender_id': 2,
    'type': 'text',
    'content': {'text': 'see you soon'},
    'created_at': '2026-11-18T00:00:00+00:00',
  },
};

const _danRequest = {
  'user': {'id': 4, 'username': 'dan', 'full_name': 'Dan', 'avatar_url': null},
  'created_at': '2026-11-18T00:00:00+00:00',
};

/// Backend for a verified user with [contacts] and [requests].
/// [onMutation] answers every other request.
FakeHttpHandler _backend({
  List<Object> contacts = const [],
  List<Object> requests = const [],
  ResponseBody Function(RequestOptions options)? onMutation,
}) {
  return (options) {
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
    if (path.endsWith('/contacts/v1/list')) return jsonResponse(contacts, 200);
    if (path.endsWith('/contacts/v1/requests')) {
      return jsonResponse(requests, 200);
    }
    return onMutation?.call(options) ?? jsonResponse({'message': 'ok'}, 200);
  };
}

Future<void> _signIn(WidgetTester tester, FakeHttpHandler backend) async {
  final cubit = await pumpAuthApp(tester, backend);
  await tester.runAsync(() => cubit.login('ana', 'Secret123'));
  await settleRequests(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump();
  await settleRequests(tester);
}

void main() {
  testWidgets('shows contacts with preview, unseen count and presence', (
    tester,
  ) async {
    await _signIn(tester, _backend(contacts: [_bob]));

    expect(find.text('Bob Ionescu'), findsOneWidget);
    expect(find.text('see you soon'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ContactAvatar),
        matching: find.byKey(const ValueKey('presence-online')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows the empty state without contacts', (tester) async {
    await _signIn(tester, _backend());

    expect(find.text('No contacts yet'), findsOneWidget);
  });

  testWidgets('accepting a request moves it into the contacts', (tester) async {
    await _signIn(tester, _backend(requests: [_danRequest]));

    await _tap(tester, find.text('Inbox'));
    expect(find.text('@dan'), findsOneWidget);

    await _tap(tester, find.text('Accept'));
    expect(find.text("You're now friends with dan."), findsOneWidget);

    // The success toast sits over the bottom bar until it closes.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('nav-chats')));
    expect(find.text('Dan'), findsOneWidget);
  });

  testWidgets('adding a contact confirms the request', (tester) async {
    await _signIn(tester, _backend());

    await _tap(tester, find.byKey(const ValueKey('add-contact')));
    await tester.enterText(
      find.descendant(
        of: find.byType(ShadDialog),
        matching: find.byType(EditableText),
      ),
      'bob',
    );
    await _tap(tester, find.text('Add'));

    expect(
      find.text('Success! Your request to befriend bob has been sent.'),
      findsOneWidget,
    );
  });

  testWidgets('adding a contact shows the backend error with the name', (
    tester,
  ) async {
    await _signIn(
      tester,
      _backend(
        onMutation: (_) =>
            jsonResponse({'detail': 'contacts.invalid_user'}, 400),
      ),
    );

    await _tap(tester, find.byKey(const ValueKey('add-contact')));
    await tester.enterText(
      find.descendant(
        of: find.byType(ShadDialog),
        matching: find.byType(EditableText),
      ),
      'ghost',
    );
    await _tap(tester, find.text('Add'));

    expect(find.text("Couldn't find a user for ghost."), findsOneWidget);
  });
}
