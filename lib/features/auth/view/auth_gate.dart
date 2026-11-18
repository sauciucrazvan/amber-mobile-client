import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/ui/amber_logo.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:amber_mobile_client/features/auth/view/signed_out_flow.dart';
import 'package:amber_mobile_client/features/auth/view/verify_account_screen.dart';
import 'package:amber_mobile_client/features/home/home_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Picks the screen for the current auth state. Every authenticated screen
/// sits behind this gate, so a signed-out user always lands on login.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      // Screens pushed while signed in (profiles, chats) must not survive
      // sign-out or an expired session.
      listenWhen: (previous, current) =>
          previous.status == AuthStatus.authenticated &&
          current.status != AuthStatus.authenticated,
      listener: (context, _) =>
          Navigator.of(context).popUntil((route) => route.isFirst),
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: switch (state.status) {
              AuthStatus.authenticated when !state.needsVerification =>
                const HomeScreen(),
              _ => Center(
                child: switch (state.status) {
                  AuthStatus.unknown => const _Loading(),
                  AuthStatus.unreachable => const _Unreachable(),
                  AuthStatus.unauthenticated => const SignedOutFlow(),
                  AuthStatus.authenticated => const VerifyAccountScreen(),
                },
              ),
            },
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
        Text(l10n.t(ApiFailure.unreachable)),
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

/// Shown while the session is restored, like the desktop's loading screen.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AmberLogo(size: 64),
        const SizedBox(height: 32),
        const SizedBox(width: 160, child: ShadProgress()),
      ],
    );
  }
}
