import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/calls/bloc/call_cubit.dart';
import 'package:amber_mobile_client/features/calls/bloc/call_state.dart';
import 'package:amber_mobile_client/features/calls/view/call_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Shows the call screen over the whole app while a call is going on, and
/// shows call problems as toasts.
class CallOverlay extends StatelessWidget {
  const CallOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<AuthCubit, AuthState>(
      // A call cannot outlive the session: its socket goes with it.
      listenWhen: (previous, current) =>
          previous.status == AuthStatus.authenticated &&
          current.status != AuthStatus.authenticated,
      listener: (context, _) => context.read<CallCubit>().reset(),
      child: BlocListener<CallCubit, CallState>(
        listenWhen: (previous, current) =>
            current.errorKey != null && current.errorKey != previous.errorKey,
        listener: (context, state) {
          ShadToaster.of(context).show(
            ShadToast.destructive(description: Text(l10n.t(state.errorKey!))),
          );
          context.read<CallCubit>().clearError();
        },
        child: BlocBuilder<CallCubit, CallState>(
          builder: (context, state) => Stack(
            children: [
              child,
              if (state.phase != CallPhase.idle)
                Positioned.fill(child: CallScreen(state: state)),
            ],
          ),
        ),
      ),
    );
  }
}
