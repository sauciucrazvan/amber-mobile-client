import 'package:amber_mobile_client/core/theme/appearance_cubit.dart';
import 'package:amber_mobile_client/features/settings/view/settings_pages.dart';
import 'package:amber_mobile_client/features/settings/view/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/auth_test_app.dart';
import '../../../support/fake_http_adapter.dart';

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
    if (path.endsWith('/contacts/v1/list')) return jsonResponse([], 200);
    if (path.endsWith('/contacts/v1/requests')) return jsonResponse([], 200);
    if (path.contains('/calls/v1/history')) {
      return jsonResponse({
        'total': 0,
        'limit': 50,
        'offset': 0,
        'calls': [],
      }, 200);
    }
    return jsonResponse({'message': 'ok'}, 200);
  };
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Amber',
      packageName: 'dev.razvansauciuc.amber_mobile_client',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('settings open from the chats header and show every section', (
    tester,
  ) async {
    final cubit = await pumpAuthApp(tester, _backend());
    await tester.runAsync(() => cubit.login('ana', 'Secret123'));
    await settleRequests(tester);

    await tester.tap(find.byKey(const ValueKey('nav-settings')));
    await settleRequests(tester);

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-general')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-account')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-devices')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-about')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings-about')));
    await settleRequests(tester);
    expect(find.text('Legal'), findsOneWidget);
    expect(find.text('1.0.0 (1)'), findsOneWidget);
  });

  testWidgets('switching the theme applies at once and is saved', (
    tester,
  ) async {
    final cubit = await pumpAuthApp(tester, _backend());
    await tester.runAsync(() => cubit.login('ana', 'Secret123'));
    await settleRequests(tester);
    await tester.tap(find.byKey(const ValueKey('nav-settings')));
    await settleRequests(tester);
    await tester.tap(find.byKey(const ValueKey('settings-general')));
    await settleRequests(tester);

    final appearance = tester
        .element(find.byType(GeneralPage))
        .read<AppearanceCubit>();
    expect(appearance.state.themeMode, ThemeMode.dark);

    await tester.tap(find.byKey(const ValueKey('dark-theme')));
    await settleRequests(tester);

    expect(appearance.state.themeMode, ThemeMode.light);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('amber.theme'), 'light');
  });
}
