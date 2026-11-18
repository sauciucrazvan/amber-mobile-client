import 'package:amber_mobile_client/app.dart';
import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/session/session_store.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/auth/data/auth_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_http_adapter.dart';
import 'support/memory_key_value_storage.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a signed-out user lands on login', (tester) async {
    final localizations = (await tester.runAsync(
      () => AppLocalizations.load('en'),
    ))!;
    final client = ApiClient(
      sessionStore: SessionStore(MemoryKeyValueStorage()),
      dio: Dio()
        ..httpClientAdapter = FakeHttpAdapter((_) => jsonResponse({}, 200)),
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

    expect(find.text('Login into your account'), findsOneWidget);
  });
}
