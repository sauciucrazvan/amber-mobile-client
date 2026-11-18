import 'dart:ui';

import 'package:amber_mobile_client/app.dart';
import 'package:amber_mobile_client/core/app_services.dart';
import 'package:amber_mobile_client/core/bloc/app_bloc_observer.dart';
import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/core/realtime/realtime_client.dart';
import 'package:amber_mobile_client/core/session/key_value_storage.dart';
import 'package:amber_mobile_client/core/session/session_store.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/auth/data/auth_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = AppBlocObserver();

  final preferredTags = PlatformDispatcher.instance.locales.map(
    (locale) => locale.toLanguageTag(),
  );
  final localizations = await AppLocalizations.load(
    resolveLocaleCode(preferredTags),
  );

  final sessionStore = SessionStore(const SecureKeyValueStorage());
  final apiClient = ApiClient(sessionStore: sessionStore);
  final realtime = RealtimeClient(
    sessionId: await sessionStore.getOrCreateSessionId(),
    readAccessToken: () async => apiClient.accessToken,
    refreshAccessToken: apiClient.refresh,
  );
  final authCubit = AuthCubit(
    api: AuthApi(apiClient),
    client: apiClient,
    connectRealtime: realtime.connect,
    disconnectRealtime: realtime.disconnect,
    accountEvents: realtime.on('account.updated'),
  )..start();

  final services = AppServices(
    apiClient: apiClient,
    realtimeEvents: realtime.events,
  );

  runApp(
    AmberApp(
      localizations: localizations,
      authCubit: authCubit,
      services: services,
    ),
  );
}
