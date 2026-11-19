import 'package:amber_mobile_client/features/contacts/view/contacts_list.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/auth_test_app.dart';
import '../../../support/fake_http_adapter.dart';

Map<String, Object?> _contact(int id, String username, String name) => {
  'user': {
    'id': id,
    'username': username,
    'full_name': name,
    'avatar_url': null,
    'online': false,
    'last_active_at': null,
  },
  'created_at': '2026-11-01T00:00:00+00:00',
  'last_action_at': '2026-11-18T00:00:00+00:00',
  'notifications': 0,
  'last_message': null,
};

FakeHttpHandler _backend() {
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
    if (path.endsWith('/contacts/v1/list')) {
      return jsonResponse([
        _contact(2, 'bob', 'Bob Ionescu'),
        _contact(3, 'carol', 'Carol Marin'),
      ], 200);
    }
    if (path.endsWith('/contacts/v1/requests')) return jsonResponse([], 200);
    return jsonResponse({'message': 'ok'}, 200);
  };
}

void main() {
  testWidgets('the search box filters contacts by name and username', (
    tester,
  ) async {
    final cubit = await pumpAuthApp(tester, _backend());
    await tester.runAsync(() => cubit.login('ana', 'Secret123'));
    await settleRequests(tester);

    expect(find.text('Bob Ionescu'), findsOneWidget);
    expect(find.text('Carol Marin'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('contacts-search')),
      'MARIN',
    );
    await tester.pumpAndSettle();
    expect(find.text('Carol Marin'), findsOneWidget);
    expect(find.text('Bob Ionescu'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('contacts-search')),
      '@bob',
    );
    await tester.pumpAndSettle();
    expect(find.text('Bob Ionescu'), findsOneWidget);
    expect(find.text('Carol Marin'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('contacts-search')),
      'zzz',
    );
    await tester.pumpAndSettle();
    expect(find.text('No contacts match your search.'), findsOneWidget);
    expect(find.byType(ContactTile), findsNothing);
  });
}
