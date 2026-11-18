import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/auth_test_app.dart';
import '../../../support/fake_http_adapter.dart';

Future<void> _openRegister(WidgetTester tester) async {
  await tester.tap(find.text('Register'));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _fillForm(WidgetTester tester) async {
  final fields = find.byType(EditableText);
  await tester.enterText(fields.at(0), 'ana');
  await tester.enterText(fields.at(1), 'Ana Pop');
  await tester.enterText(fields.at(2), 'ana@example.com');
  await tester.enterText(fields.at(3), 'Secret123');
}

void main() {
  testWidgets('switches between login and register', (tester) async {
    await pumpAuthApp(tester, (_) => jsonResponse({}, 200));

    await _openRegister(tester);
    expect(find.text('Create an account'), findsOneWidget);

    await _tapVisible(tester, find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Login into your account'), findsOneWidget);
  });

  testWidgets('asks for input when fields are empty', (tester) async {
    await pumpAuthApp(tester, (_) => jsonResponse({}, 200));
    await _openRegister(tester);

    await _tapVisible(tester, find.text('Create your account'));

    expect(find.text('Fill in the input fields'), findsOneWidget);
  });

  testWidgets('shows backend errors under their fields', (tester) async {
    await pumpAuthApp(tester, (options) {
      if (options.path.endsWith('/auth/v1/register')) {
        return jsonResponse({
          'detail': {
            'errors': [
              {'field': 'username', 'error': 'register.usernameTaken'},
              {'field': 'email', 'error': 'register.emailTaken'},
            ],
          },
        }, 422);
      }
      return jsonResponse({}, 200);
    });
    await _openRegister(tester);

    await _fillForm(tester);
    await _tapVisible(tester, find.text('Create your account'));
    await settleRequests(tester);

    expect(find.text('Username is already taken.'), findsOneWidget);
    expect(find.text('Email is already registered.'), findsOneWidget);
  });

  testWidgets('a successful register signs the user in', (tester) async {
    final cubit = await pumpAuthApp(tester, (options) {
      if (options.path.endsWith('/auth/v1/register')) {
        return jsonResponse({'id': 1, 'username': 'ana'}, 201);
      }
      if (options.path.endsWith('/auth/v1/login')) {
        return jsonResponse({
          'access_token': 'access-1',
          'refresh_token': 'refresh-1',
          'token_type': 'bearer',
        }, 200);
      }
      return jsonResponse({
        'id': 1,
        'username': 'ana',
        'full_name': 'Ana Pop',
        'verified': false,
      }, 200);
    });
    await _openRegister(tester);

    await _fillForm(tester);
    await _tapVisible(tester, find.text('Create your account'));
    await settleRequests(tester);

    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.needsVerification, isTrue);
  });

  testWidgets('the terms link opens the terms dialog', (tester) async {
    await pumpAuthApp(tester, (_) => jsonResponse({}, 200));
    await _openRegister(tester);

    final link = find.textRange.ofSubstring('terms & conditions');
    await tester.ensureVisible(find.textContaining('terms & conditions'));
    await tester.pumpAndSettle();
    await tester.tapOnText(link);
    await tester.pumpAndSettle();

    expect(find.text('Terms & Conditions'), findsOneWidget);
  });
}
