import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/theme/app_theme.dart';
import 'package:amber_mobile_client/core/theme/appearance_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Root widget. Feature screens are added here as they are built.
class AmberApp extends StatelessWidget {
  const AmberApp({super.key, required this.localizations});

  final AppLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    return AppLocalizationsScope(
      localizations: localizations,
      child: BlocProvider(
        create: (_) => AppearanceCubit()..load(),
        child: BlocBuilder<AppearanceCubit, AppearanceState>(
          builder: (context, appearance) {
            return MaterialApp(
              title: 'Amber',
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: appearance.themeMode,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(appearance.fontScale)),
                child: child!,
              ),
              home: const Scaffold(body: Center(child: Text('Amber'))),
            );
          },
        ),
      ),
    );
  }
}
