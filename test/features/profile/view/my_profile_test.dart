import 'package:amber_mobile_client/core/theme/app_theme.dart';

import 'package:amber_mobile_client/features/auth/data/account.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/profile/view/my_profile_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../support/auth_test_app.dart';
import '../../../support/fake_http_adapter.dart';

FakeHttpHandler _backend({List<String>? logouts}) {
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
        'bio': 'Hello from Ana',
        'verified': true,
        'registered_at': '2026-01-02T00:00:00+00:00',
        'last_active_at': '2026-11-18T09:00:00+00:00',
      }, 200);
    }
    if (path.endsWith('/contacts/v1/list') ||
        path.endsWith('/contacts/v1/requests')) {
      return jsonResponse([], 200);
    }
    logouts?.add(path);
    return jsonResponse({'message': 'ok'}, 200);
  };
}

Future<AuthCubit> _signIn(WidgetTester tester, FakeHttpHandler backend) async {
  final cubit = await pumpAuthApp(tester, backend);
  await tester.runAsync(() => cubit.login('ana', 'Secret123'));
  await settleRequests(tester);
  return cubit;
}

void main() {
  test('account reads bio, avatar and dates from /me', () {
    final account = Account.fromJson({
      'id': 1,
      'username': 'ana',
      'bio': 'Hi',
      'avatar_url': 'https://files.example.com/a.png',
      'registered_at': '2026-01-02T00:00:00+00:00',
      'verified': true,
    });

    expect(account.bio, 'Hi');
    expect(account.avatarUrl, 'https://files.example.com/a.png');
    expect(account.registeredAt, DateTime.utc(2026, 1, 2));
    expect(account.verified, isTrue);
  });

  test('the desktop neutral palette is used in both modes', () {
    expect(AppTheme.light().colorScheme.background, const Color(0xFFFFFFFF));
    expect(AppTheme.dark().colorScheme.background, const Color(0xFF0A0A0A));
    expect(AppTheme.light().colorScheme.primary, const Color(0xFF171717));
    expect(AppTheme.dark().colorScheme.primary, const Color(0xFFE5E5E5));
    expect(AppColors.brand, const Color(0xFFFF9831));
  });

  testWidgets('the avatar in the header opens my profile', (tester) async {
    await _signIn(tester, _backend());

    await tester.tap(find.byKey(const ValueKey('my-profile')));
    await tester.pumpAndSettle();

    expect(find.byType(MyProfileScreen), findsOneWidget);
    expect(find.text('Ana Pop'), findsOneWidget);
    expect(find.text('@ana'), findsOneWidget);
    expect(find.text('Hello from Ana'), findsOneWidget);
  });

  testWidgets('sign out asks first, and cancelling keeps the session', (
    tester,
  ) async {
    final cubit = await _signIn(tester, _backend());
    await tester.tap(find.byKey(const ValueKey('my-profile')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sign-out')));
    await tester.pumpAndSettle();
    expect(find.byType(ShadDialog), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(cubit.state.status, AuthStatus.authenticated);
  });

  testWidgets('confirming sign out ends the session', (tester) async {
    final cubit = await _signIn(tester, _backend());
    await tester.tap(find.byKey(const ValueKey('my-profile')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(ShadDialog).last,
        matching: find.widgetWithText(ShadButton, 'Sign out'),
      ),
    );
    await tester.pumpAndSettle();

    expect(cubit.state.status, AuthStatus.unauthenticated);
  });
}
