import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/auth/data/auth_failure.dart';
import 'package:amber_mobile_client/features/auth/view/legal_dialog.dart';
import 'package:amber_mobile_client/features/auth/view/widgets/auth_form_layout.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onLogin});

  final VoidCallback onLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _username = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _errorKey;
  Map<String, String> _fieldErrors = const {};
  bool _submitting = false;

  @override
  void dispose() {
    _username.dispose();
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _username.text.trim();
    final fullName = _fullName.text.trim();
    final email = _email.text.trim();
    final password = _password.text;
    if ([username, fullName, email, password].any((value) => value.isEmpty)) {
      setState(() {
        _errorKey = 'register.fillInput';
        _fieldErrors = const {};
      });
      return;
    }

    setState(() {
      _errorKey = null;
      _fieldErrors = const {};
      _submitting = true;
    });
    try {
      await context.read<AuthCubit>().register(
        username: username,
        fullName: fullName,
        email: email,
        password: password,
      );
    } on AuthFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        _fieldErrors = failure.fieldErrors;
        _errorKey = failure.fieldErrors.isEmpty ? failure.messageKey : null;
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errorKey = _errorKey;

    return AuthFormLayout(
      title: l10n.t('register.title'),
      subtitle: l10n.t('register.subtitle'),
      children: [
        AuthErrorAlert(message: errorKey == null ? null : l10n.t(errorKey)),
        _RegisterField(
          controller: _username,
          placeholder: l10n.t('register.usernamePlaceholder'),
          hint: l10n.t('register.usernameHint'),
          errorKey: _fieldErrors['username'],
          autofillHints: const [AutofillHints.newUsername],
          enabled: !_submitting,
        ),
        _RegisterField(
          controller: _fullName,
          placeholder: l10n.t('register.fullnamePlaceholder'),
          errorKey: _fieldErrors['full_name'],
          autofillHints: const [AutofillHints.name],
          enabled: !_submitting,
        ),
        _RegisterField(
          controller: _email,
          placeholder: l10n.t('register.emailPlaceholder'),
          hint: l10n.t('register.emailHint'),
          errorKey: _fieldErrors['email'],
          autofillHints: const [AutofillHints.email],
          keyboardType: TextInputType.emailAddress,
          enabled: !_submitting,
        ),
        _RegisterField(
          controller: _password,
          placeholder: l10n.t('register.passwordPlaceholder'),
          hint: l10n.t('register.passwordHint'),
          errorKey: _fieldErrors['password'],
          autofillHints: const [AutofillHints.newPassword],
          obscureText: true,
          enabled: !_submitting,
        ),
        const SizedBox(height: 8),
        ShadButton(
          onPressed: _submitting ? null : _submit,
          child: Text(l10n.t('register.createAccount')),
        ),
        const SizedBox(height: 16),
        const _TermsNotice(),
        const SizedBox(height: 8),
        AuthSwitchPrompt(
          prompt: l10n.t('register.loginPrompt'),
          linkLabel: l10n.t('register.loginLink'),
          onPressed: _submitting ? null : widget.onLogin,
        ),
      ],
    );
  }
}

class _RegisterField extends StatelessWidget {
  const _RegisterField({
    required this.controller,
    required this.placeholder,
    required this.autofillHints,
    required this.enabled,
    this.hint,
    this.errorKey,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String placeholder;
  final List<String> autofillHints;
  final bool enabled;
  final String? hint;
  final String? errorKey;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final errorKey = this.errorKey;
    final hint = this.hint;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShadInput(
            controller: controller,
            placeholder: Text(placeholder),
            autofillHints: autofillHints,
            autocorrect: false,
            keyboardType: keyboardType,
            obscureText: obscureText,
            enabled: enabled,
          ),
          if (errorKey != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                AppLocalizations.of(context).t(errorKey),
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.destructive,
                ),
              ),
            )
          else if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(hint, style: theme.textTheme.muted),
            ),
        ],
      ),
    );
  }
}

/// Renders `register.terms`, where `<terms>` and `<privacy>` mark the links.
class _TermsNotice extends StatefulWidget {
  const _TermsNotice();

  @override
  State<_TermsNotice> createState() => _TermsNoticeState();
}

class _TermsNoticeState extends State<_TermsNotice> {
  static final _tag = RegExp(r'<(terms|privacy)>(.*?)</\1>');
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final text = AppLocalizations.of(context).t('register.terms');

    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in _tag.allMatches(text)) {
      spans.add(TextSpan(text: text.substring(start, match.start)));
      final document = match.group(1) == 'terms'
          ? LegalDocument.terms
          : LegalDocument.privacy;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => showLegalDialog(context, document);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: match.group(2),
          style: const TextStyle(decoration: TextDecoration.underline),
          recognizer: recognizer,
        ),
      );
      start = match.end;
    }
    spans.add(TextSpan(text: text.substring(start)));

    return Text.rich(
      TextSpan(style: theme.textTheme.muted, children: spans),
      textAlign: TextAlign.center,
    );
  }
}
