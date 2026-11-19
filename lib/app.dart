import 'package:amber_mobile_client/core/app_services.dart';
import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/theme/app_theme.dart';
import 'package:amber_mobile_client/core/theme/appearance_cubit.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/auth/view/auth_gate.dart';
import 'package:amber_mobile_client/features/calls/view/call_overlay.dart';
import 'package:amber_mobile_client/features/calls/view/calls_scope.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Root widget. Feature screens are added here as they are built.
class AmberApp extends StatelessWidget {
  const AmberApp({
    super.key,
    required this.localizations,
    required this.authCubit,
    required this.services,
  });

  final AppLocalizations localizations;
  final AuthCubit authCubit;
  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return AppLocalizationsScope(
      localizations: localizations,
      child: RepositoryProvider.value(
        value: services,
        child: CallsScope(
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: authCubit),
              BlocProvider(create: (_) => AppearanceCubit()..load()),
            ],
            child: BlocBuilder<AppearanceCubit, AppearanceState>(
              builder: (context, appearance) {
                return ShadApp.custom(
                  theme: AppTheme.light(),
                  darkTheme: AppTheme.dark(),
                  themeMode: appearance.themeMode,
                  appBuilder: (context) => MaterialApp(
                    title: 'Amber',
                    // ShadApp.custom provides a Material theme built from the
                    // active shadcn theme. Without it, Material surfaces such as
                    // Scaffold stay light regardless of the theme mode.
                    theme: Theme.of(context),
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(appearance.fontScale),
                      ),
                      // ShadApp.custom does not add a toaster, so screens can
                      // only show toasts through this one.
                      child: ShadToaster(child: CallOverlay(child: child!)),
                    ),
                    home: const AuthGate(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
