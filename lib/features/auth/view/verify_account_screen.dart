import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/auth/data/auth_failure.dart';
import 'package:amber_mobile_client/features/auth/view/widgets/auth_form_layout.dart';
import 'package:amber_mobile_client/features/auth/view/widgets/code_input.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Shown by the gate while the signed-in account is unverified.
/// Step one emails a code, step two submits it.
class VerifyAccountScreen extends StatefulWidget {
  const VerifyAccountScreen({super.key});

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen> {
  bool _codeSent = false;
  String _code = '';
  String? _errorKey;
  String? _infoKey;
  bool _submitting = false;

  Future<void> _run(Future<void> Function(AuthCubit cubit) action) async {
    setState(() {
      _errorKey = null;
      _infoKey = null;
      _submitting = true;
    });
    final cubit = context.read<AuthCubit>();
    try {
      try {
        await action(cubit);
      } on AuthFailure catch (failure) {
        // Verified elsewhere: reload so the gate opens the app.
        if (failure.messageKey != 'register.verify.already_verified') rethrow;
        await cubit.refreshAccount();
      }
    } on AuthFailure catch (failure) {
      if (mounted) _onFailure(failure);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _onFailure(AuthFailure failure) {
    setState(() {
      _errorKey = failure.messageKey;
      // A code was already sent in the last 30 minutes: let the user enter it.
      if (failure.messageKey == 'register.verify.too_soon') _codeSent = true;
    });
  }

  Future<void> _send() => _run((cubit) async {
    await cubit.requestVerification();
    setState(() {
      _codeSent = true;
      _infoKey = 'register.verify.email_sent';
    });
  });

  Future<void> _verify() => _run((cubit) => cubit.verify(_code));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errorKey = _errorKey;
    final infoKey = _infoKey;

    return AuthFormLayout(
      title: l10n.t('register.verify.title'),
      subtitle: l10n.t(
        _codeSent
            ? 'register.verify.description.step_two'
            : 'register.verify.description.step_one',
      ),
      children: [
        AuthErrorAlert(message: errorKey == null ? null : l10n.t(errorKey)),
        if (infoKey != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ShadAlert(description: Text(l10n.t(infoKey))),
          ),
        if (_codeSent) ...[
          CodeInput(
            enabled: !_submitting,
            onChanged: (code) => setState(() => _code = code),
          ),
          const SizedBox(height: 20),
          ShadButton(
            onPressed: _submitting || _code.length != CodeInput.length
                ? null
                : _verify,
            child: Text(l10n.t('register.verify.action.finish')),
          ),
          ShadButton.ghost(
            onPressed: _submitting
                ? null
                : () => setState(() {
                    _codeSent = false;
                    _code = '';
                    _errorKey = null;
                    _infoKey = null;
                  }),
            child: Text(l10n.t('register.verify.action.back')),
          ),
        ] else
          ShadButton(
            onPressed: _submitting ? null : _send,
            child: Text(l10n.t('register.verify.action.next')),
          ),
        const SizedBox(height: 16),
        ShadButton.link(
          onPressed: _submitting
              ? null
              : () => context.read<AuthCubit>().signOut(),
          child: Text(l10n.t('settings.account.signOut.action')),
        ),
      ],
    );
  }
}
