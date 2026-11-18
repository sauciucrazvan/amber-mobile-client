import 'dart:ui';

import 'package:amber_mobile_client/app.dart';
import 'package:amber_mobile_client/core/bloc/app_bloc_observer.dart';
import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
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
  runApp(AmberApp(localizations: localizations));
}
