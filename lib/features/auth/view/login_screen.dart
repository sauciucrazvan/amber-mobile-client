import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:amber_mobile_client/features/auth/view/widgets/auth_form_layout.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onRegister,
    required this.onForgotPassword,
    this.infoKey,
  });

  final VoidCallback onRegister;
  final VoidCallback onForgotPassword;

  /// Translation key for a notice, such as a successful password reset.
  final String? infoKey;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  String? _errorKey;
  bool _submitting = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _username.text.trim();
    final password = _password.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorKey = ApiFailure.fillInput);
      return;
    }

    setState(() {
      _errorKey = null;
      _submitting = true;
    });
    try {
      await context.read<AuthCubit>().login(username, password);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => _errorKey = failure.messageKey);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errorKey = _errorKey;
    final infoKey = widget.infoKey;

    return AuthFormLayout(
      title: l10n.t('login.title'),
      subtitle: l10n.t('login.subtitle'),
      children: [
        AuthErrorAlert(message: errorKey == null ? null : l10n.t(errorKey)),
        if (infoKey != null && errorKey == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ShadAlert(description: Text(l10n.t(infoKey))),
          ),
        ShadInput(
          controller: _username,
          placeholder: Text(l10n.t('login.usernamePlaceholder')),
          autofillHints: const [AutofillHints.username],
          autocorrect: false,
          textInputAction: TextInputAction.next,
          enabled: !_submitting,
        ),
        const SizedBox(height: 12),
        ShadInput(
          controller: _password,
          placeholder: Text(l10n.t('login.passwordPlaceholder')),
          autofillHints: const [AutofillHints.password],
          obscureText: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          enabled: !_submitting,
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ShadButton.link(
            onPressed: _submitting ? null : widget.onForgotPassword,
            child: Text(l10n.t('login.forgotPassword')),
          ),
        ),
        const SizedBox(height: 8),
        ShadButton(
          onPressed: _submitting ? null : _submit,
          child: Text(l10n.t('login.signIn')),
        ),
        const SizedBox(height: 16),
        AuthSwitchPrompt(
          prompt: l10n.t('login.registerPrompt'),
          linkLabel: l10n.t('login.registerLink'),
          onPressed: _submitting ? null : widget.onRegister,
        ),
      ],
    );
  }
}
