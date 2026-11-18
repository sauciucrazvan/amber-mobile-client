import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/auth/data/auth_failure.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Picks the screen for the current auth state. Every authenticated screen
/// sits behind this gate, so a signed-out user always lands on login.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: switch (state.status) {
                AuthStatus.unknown => const SizedBox(
                  width: 160,
                  child: ShadProgress(),
                ),
                AuthStatus.unreachable => const _Unreachable(),
                AuthStatus.unauthenticated => const _SignedOut(),
                AuthStatus.authenticated => const _SignedIn(),
              },
            ),
          ),
        );
      },
    );
  }
}

class _Unreachable extends StatelessWidget {
  const _Unreachable();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.t(AuthFailure.unreachable)),
        const SizedBox(height: 16),
        ShadButton(
          onPressed: () => context.read<AuthCubit>().start(),
          // No shared translation key for "Retry" exists yet.
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

/// Placeholder until the login screen lands.
class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) {
    return Text(AppLocalizations.of(context).t('login.title'));
  }
}

/// Placeholder for the main screen.
class _SignedIn extends StatelessWidget {
  const _SignedIn();

  @override
  Widget build(BuildContext context) {
    final account = context.select((AuthCubit cubit) => cubit.state.account);
    return ShadCard(
      title: Text(account?.fullName ?? account?.username ?? 'Amber'),
      footer: ShadButton.outline(
        onPressed: () => context.read<AuthCubit>().signOut(),
        child: Text(
          AppLocalizations.of(context).t('settings.account.signOut.action'),
        ),
      ),
    );
  }
}
