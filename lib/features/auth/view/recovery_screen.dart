import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:amber_mobile_client/features/auth/view/widgets/auth_form_layout.dart';
import 'package:amber_mobile_client/features/auth/view/widgets/code_input.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum _RecoveryStep { username, code, password }

/// Password recovery: request a code for a username, enter the code, then
/// choose a new password. Mirrors the desktop's three-stage dialog.
class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({
    super.key,
    required this.onCancel,
    required this.onReset,
  });

  final VoidCallback onCancel;

  /// Called after the password changed, so the user can log in again.
  final VoidCallback onReset;

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  _RecoveryStep _step = _RecoveryStep.username;
  String _code = '';
  String? _errorKey;
  String? _infoKey;
  bool _submitting = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(AuthCubit cubit) action) async {
    setState(() {
      _errorKey = null;
      _infoKey = null;
      _submitting = true;
    });
    try {
      await action(context.read<AuthCubit>());
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _errorKey = failure.messageKey;
        _step = switch (failure.messageKey) {
          // A code was requested in the last 30 minutes: let the user enter it.
          'login.recovery.too_soon' ||
          'login.recovery.invalid_code' => _RecoveryStep.code,
          // The code expired: a new one has to be requested.
          'login.recovery.too_late' => _RecoveryStep.username,
          _ => _step,
        };
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _next() async {
    switch (_step) {
      case _RecoveryStep.username:
        final username = _username.text.trim();
        if (username.isEmpty) {
          setState(() => _errorKey = 'login.recovery.invalid_username');
          return;
        }
        await _run((cubit) async {
          await cubit.requestRecovery(username);
          setState(() {
            _step = _RecoveryStep.code;
            _infoKey = 'login.recovery.sent';
          });
        });
      case _RecoveryStep.code:
        setState(() {
          _errorKey = null;
          _infoKey = null;
          _step = _RecoveryStep.password;
        });
      case _RecoveryStep.password:
        if (_password.text != _confirmation.text) {
          setState(() => _errorKey = 'login.recovery.different_passwords');
          return;
        }
        await _run((cubit) async {
          await cubit.resetPassword(
            username: _username.text.trim(),
            code: _code,
            newPassword: _password.text,
            newPasswordConfirmation: _confirmation.text,
          );
          widget.onReset();
        });
    }
  }

  void _back() {
    setState(() {
      _errorKey = null;
      _infoKey = null;
      _step = _step == _RecoveryStep.password
          ? _RecoveryStep.code
          : _RecoveryStep.username;
    });
  }

  bool get _canContinue => switch (_step) {
    _RecoveryStep.username => true,
    _RecoveryStep.code => _code.length == CodeInput.length,
    _RecoveryStep.password => _password.text.isNotEmpty,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errorKey = _errorKey;
    final infoKey = _infoKey;

    return AuthFormLayout(
      title: l10n.t('login.recovery.title'),
      subtitle: l10n.t('login.recovery.description'),
      children: [
        AuthErrorAlert(message: errorKey == null ? null : l10n.t(errorKey)),
        if (infoKey != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ShadAlert(description: Text(l10n.t(infoKey))),
          ),
        ...switch (_step) {
          _RecoveryStep.username => [
            Text(l10n.t('login.recovery.username')),
            const SizedBox(height: 8),
            ShadInput(
              controller: _username,
              placeholder: Text(l10n.t('login.usernamePlaceholder')),
              autofillHints: const [AutofillHints.username],
              autocorrect: false,
              enabled: !_submitting,
            ),
          ],
          _RecoveryStep.code => [
            Text(l10n.t('login.recovery.code')),
            const SizedBox(height: 8),
            CodeInput(
              enabled: !_submitting,
              onChanged: (code) => setState(() => _code = code),
            ),
          ],
          _RecoveryStep.password => [
            Text(l10n.t('login.recovery.password')),
            const SizedBox(height: 8),
            ShadInput(
              controller: _password,
              placeholder: Text(
                l10n.t('settings.account.password.new_password'),
              ),
              autofillHints: const [AutofillHints.newPassword],
              obscureText: true,
              enabled: !_submitting,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            ShadInput(
              controller: _confirmation,
              placeholder: Text(
                l10n.t('settings.account.password.new_password_confirmation'),
              ),
              autofillHints: const [AutofillHints.newPassword],
              obscureText: true,
              enabled: !_submitting,
            ),
          ],
        },
        const SizedBox(height: 20),
        ShadButton(
          onPressed: _submitting || !_canContinue ? null : _next,
          child: Text(
            l10n.t(
              _step == _RecoveryStep.password
                  ? 'login.recovery.action.finish'
                  : 'login.recovery.action.next',
            ),
          ),
        ),
        ShadButton.ghost(
          onPressed: _submitting
              ? null
              : _step == _RecoveryStep.username
              ? widget.onCancel
              : _back,
          child: Text(
            l10n.t(
              _step == _RecoveryStep.username
                  ? 'common.cancel'
                  : 'login.recovery.action.back',
            ),
          ),
        ),
      ],
    );
  }
}
