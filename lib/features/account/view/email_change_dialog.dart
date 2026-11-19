import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:amber_mobile_client/core/ui/amber_dialog.dart';
import 'package:amber_mobile_client/features/account/data/account_api.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The steps of an email change, in order. The confirm step is skipped when
/// the server sends the code straight to the new address.
enum _Step { request, confirm, verify }

/// Changes the account's email in three steps, as on the desktop: request the
/// change with the password, enter the code sent to the current email (when
/// needed), then enter the code sent to the new email. Resolves to true once
/// the email has changed.
class EmailChangeDialog extends StatefulWidget {
  const EmailChangeDialog({super.key, required this.api});

  final AccountApi api;

  @override
  State<EmailChangeDialog> createState() => _EmailChangeDialogState();
}

class _EmailChangeDialogState extends State<EmailChangeDialog> {
  _Step _step = _Step.request;
  String _newEmail = '';
  bool _busy = false;
  String? _errorKey;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() {
      _busy = true;
      _errorKey = null;
    });
    try {
      switch (_step) {
        case _Step.request:
          final email = _email.text.trim();
          if (!email.contains('@')) {
            setState(() => _errorKey = 'register.invalidEmail');
            return;
          }
          _newEmail = email;
          final message = await widget.api.requestEmailChange(
            email: email,
            password: _password.text,
          );
          _advance(
            message == 'settings.account.email.verify_sent'
                ? _Step.verify
                : _Step.confirm,
          );
        case _Step.confirm:
          final message = await widget.api.confirmEmailChange(
            _code.text.trim(),
          );
          _advance(
            message == 'settings.account.email.verify_sent'
                ? _Step.verify
                : _Step.confirm,
          );
          _code.clear();
        case _Step.verify:
          await widget.api.verifyEmailChange(_code.text.trim());
          if (mounted) Navigator.of(context).pop(true);
      }
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _errorKey = failure.messageKey);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _advance(_Step next) {
    if (!mounted) return;
    setState(() => _step = next);
  }

  /// The description for the current step. The server's text has `<b>` tags
  /// around the address, which are dropped here.
  String _description(AppLocalizations l10n) {
    return switch (_step) {
      _Step.request => l10n.t('settings.account.email.request_description'),
      _Step.confirm => l10n.t('settings.account.email.confirm_description'),
      _Step.verify =>
        l10n
            .t(
              'settings.account.email.verify_description',
              params: {'email': _newEmail},
            )
            .replaceAll(RegExp(r'</?b>'), ''),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errorKey = _errorKey;
    return AmberDialog(
      title: Text(l10n.t('settings.account.email.title')),
      description: Text(_description(l10n)),
      actions: [
        ShadButton.outline(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.t('common.cancel')),
        ),
        ShadButton(
          key: const ValueKey('email-continue'),
          onPressed: _busy ? null : _continue,
          child: Text(l10n.t('settings.account.name.action')),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          switch (_step) {
            _Step.request => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShadInput(
                  key: const ValueKey('email-new'),
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  placeholder: Text(l10n.t('register.emailPlaceholder')),
                ),
                const SizedBox(height: 8),
                ShadInput(
                  key: const ValueKey('email-password'),
                  controller: _password,
                  obscureText: true,
                  placeholder: Text(
                    l10n.t('settings.account.password.current_password'),
                  ),
                ),
              ],
            ),
            _Step.confirm => ShadInput(
              key: const ValueKey('email-code'),
              controller: _code,
              placeholder: Text(l10n.t('settings.account.email.confirm_code')),
            ),
            _Step.verify => ShadInput(
              key: const ValueKey('email-code'),
              controller: _code,
              placeholder: Text(l10n.t('settings.account.email.verify_code')),
            ),
          },
          if (errorKey != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.t(errorKey),
              style: TextStyle(
                color: ShadTheme.of(context).colorScheme.destructive,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
