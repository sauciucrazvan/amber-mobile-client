import 'package:amber_mobile_client/app.dart';
import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/session/session_store.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/auth/data/auth_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_http_adapter.dart';
import 'memory_key_value_storage.dart';

/// Pumps the whole app against a fake backend and returns its auth cubit.
Future<AuthCubit> pumpAuthApp(
  WidgetTester tester,
  FakeHttpHandler handler,
) async {
  SharedPreferences.setMockInitialValues({});
  final localizations = (await tester.runAsync(
    () => AppLocalizations.load('en'),
  ))!;
  final client = ApiClient(
    sessionStore: SessionStore(MemoryKeyValueStorage()),
    dio: Dio()..httpClientAdapter = FakeHttpAdapter(handler),
  );
  final authCubit = AuthCubit(
    api: AuthApi(client),
    client: client,
    connectRealtime: () async {},
    disconnectRealtime: () async {},
  );
  addTearDown(authCubit.close);
  await tester.runAsync(authCubit.start);

  await tester.pumpWidget(
    AmberApp(localizations: localizations, authCubit: authCubit),
  );
  await tester.pumpAndSettle();
  return authCubit;
}

/// Lets pending fake HTTP calls finish outside the fake clock, then settles
/// the widget tree.
Future<void> settleRequests(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}
