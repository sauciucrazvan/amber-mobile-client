import 'package:amber_mobile_client/app.dart';
import 'package:amber_mobile_client/core/app_services.dart';
import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/session/session_store.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/auth/data/auth_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_http_adapter.dart';
import 'support/memory_key_value_storage.dart';

void main() {
  testWidgets('Material surfaces follow the shadcn theme mode', (tester) async {
    SharedPreferences.setMockInitialValues({'amber.theme': 'dark'});
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
      AmberApp(
        localizations: localizations,
        authCubit: authCubit,
        services: AppServices(apiClient: client),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
