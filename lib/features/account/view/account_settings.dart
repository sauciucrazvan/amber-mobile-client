import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:amber_mobile_client/core/ui/amber_dialog.dart';
import 'package:amber_mobile_client/core/ui/confirmation_dialog.dart';
import 'package:amber_mobile_client/features/account/data/account_api.dart';
import 'package:file_picker/file_picker.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:amber_mobile_client/features/auth/data/account.dart';
import 'package:amber_mobile_client/core/app_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The account rows in Settings: name, bio, password and privacy. Each change
/// saves on the server, refreshes the account, and shows a toast.
class AccountSettings extends StatelessWidget {
  const AccountSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final account = context.select((AuthCubit cubit) => cubit.state.account);
    if (account == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AccountRow(
          title: l10n.t('settings.account.name.title'),
          description: l10n.t('settings.account.name.description'),
          buttonKey: const ValueKey('account-name'),
          buttonLabel: l10n.t('settings.account.name.action'),
          onPressed: () => _editName(context, account),
        ),
        _AccountRow(
          title: l10n.t('profile.bio.title'),
          description: account.bio?.trim().isEmpty ?? true
              ? l10n.t('profile.bio.empty')
              : account.bio!.trim(),
          buttonKey: const ValueKey('account-bio'),
          buttonLabel: l10n.t('settings.account.name.action'),
          onPressed: () => _editBio(context, account),
        ),
        _AccountRow(
          title: l10n.t('settings.account.password.title'),
          description: l10n.t('settings.account.password.description'),
          buttonKey: const ValueKey('account-password'),
          buttonLabel: l10n.t('settings.account.password.action'),
          onPressed: () => _changePassword(context),
        ),
        _PrivacyRow(account: account),
        _AccountRow(
          title: l10n.t('settings.account.avatar.confirm.title'),
          description: l10n.t('settings.account.avatar.confirm.description'),
          buttonKey: const ValueKey('account-avatar'),
          buttonLabel: l10n.t('settings.account.avatar.confirm.upload'),
          onPressed: () => _changeAvatar(context),
        ),
        _AccountRow(
          title: l10n.t('settings.account.data.title'),
          description: l10n.t('settings.account.data.description'),
          buttonKey: const ValueKey('account-data'),
          buttonLabel: l10n.t('settings.account.data.action'),
          onPressed: () => _requestData(context),
        ),
        _AccountRow(
          title: l10n.t('settings.account.delete.title'),
          description: l10n.t('settings.account.delete.description'),
          buttonKey: const ValueKey('account-delete'),
          buttonLabel: l10n.t('settings.account.delete.action'),
          onPressed: () => _deleteAccount(context),
          destructive: true,
        ),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.title,
    required this.description,
    required this.buttonKey,
    required this.buttonLabel,
    required this.onPressed,
    this.destructive = false,
  });

  final String title;
  final String description;
  final Key buttonKey;
  final String buttonLabel;
  final VoidCallback onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.small),
                Text(
                  description,
                  style: theme.textTheme.muted,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (destructive)
            ShadButton.destructive(
              key: buttonKey,
              size: ShadButtonSize.sm,
              onPressed: onPressed,
              child: Text(buttonLabel),
            )
          else
            ShadButton.outline(
              key: buttonKey,
              size: ShadButtonSize.sm,
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
        ],
      ),
    );
  }
}

class _PrivacyRow extends StatelessWidget {
  const _PrivacyRow({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('settings.account.privacy.allow_add_by_email.title'),
                  style: theme.textTheme.small,
                ),
                Text(
                  l10n.t(
                    'settings.account.privacy.allow_add_by_email.subtitle',
                  ),
                  style: theme.textTheme.muted,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ShadSwitch(
            key: const ValueKey('privacy-add-by-email'),
            value: account.allowAddByEmail,
            onChanged: (value) => _run(
              context,
              () =>
                  _api(context).setPrivacy('allow_add_by_email', value: value),
              // The switch shows its state, so it needs no toast.
              successKey: null,
            ),
          ),
        ],
      ),
    );
  }
}

AccountApi _api(BuildContext context) =>
    AccountApi(context.read<AppServices>().apiClient);

Future<void> _editName(BuildContext context, Account account) async {
  final l10n = AppLocalizations.of(context);
  final value = await _askText(
    context,
    title: l10n.t('settings.account.name.title'),
    description: l10n.t('settings.account.name.description'),
    initial: account.fullName ?? '',
    action: l10n.t('settings.account.name.action'),
  );
  if (value == null || !context.mounted) return;
  final name = value.trim();
  if (name.isEmpty) return;
  if (name == (account.fullName ?? '').trim()) {
    _toast(context, 'settings.account.name.same', error: true);
    return;
  }
  await _run(
    context,
    () => _api(context).updateName(name),
    successKey: 'settings.account.name.updated',
  );
}

Future<void> _editBio(BuildContext context, Account account) async {
  final l10n = AppLocalizations.of(context);
  final value = await _askText(
    context,
    title: l10n.t('profile.bio.title'),
    description: l10n.t('settings.account.bio.description'),
    initial: account.bio ?? '',
    action: l10n.t('settings.account.name.action'),
    lines: 4,
  );
  if (value == null || !context.mounted) return;
  final bio = value.trim();
  if (bio.length > 256) {
    _toast(context, 'settings.account.bio.too_long', error: true);
    return;
  }
  await _run(
    context,
    () => _api(context).updateBio(bio),
    successKey: 'settings.account.bio.updated',
  );
}

/// Picks an image, checks its type and size, confirms, then uploads it.
Future<void> _changeAvatar(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final picked = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: avatarContentTypes.keys.toList(),
  );
  if (picked.isEmpty || !context.mounted) return;
  final file = picked.first;
  final contentType = avatarContentTypes[file.extension?.toLowerCase()];
  if (contentType == null) {
    _toast(context, 'settings.account.avatar.invalidType', error: true);
    return;
  }
  final size = await file.length() ?? 0;
  if (!context.mounted) return;
  if (size > avatarMaxBytes) {
    _toast(context, 'settings.account.avatar.tooBig', error: true);
    return;
  }
  final confirmed = await showConfirmationDialog(
    context,
    title: l10n.t('settings.account.avatar.confirm.title'),
    description: l10n.t('settings.account.avatar.confirm.description'),
    confirmText: l10n.t('settings.account.avatar.confirm.upload'),
  );
  if (!confirmed || !context.mounted) return;
  final bytes = await file.readAsBytes();
  if (!context.mounted) return;
  await _run(
    context,
    () => _api(
      context,
    ).uploadAvatar(bytes: bytes, filename: file.name, contentType: contentType),
    successKey: 'settings.account.avatar.uploaded',
  );
}

Future<void> _requestData(BuildContext context) => _run(
  context,
  () => _api(context).requestData(),
  successKey: 'settings.account.data.toast',
  refresh: false,
);

/// Deletes the account after the password and a second confirmation. The
/// session is then cleared, so the app returns to sign-in.
Future<void> _deleteAccount(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final password = await showShadDialog<String>(
    context: context,
    builder: (_) => const _DeleteDialog(),
  );
  if (password == null || !context.mounted) return;
  final confirmed = await showConfirmationDialog(
    context,
    title: l10n.t('settings.account.delete.title'),
    description: l10n.t('settings.account.delete.description'),
    confirmText: l10n.t('settings.account.delete.action'),
    destructive: true,
  );
  if (!confirmed || !context.mounted) return;
  final authCubit = context.read<AuthCubit>();
  try {
    await _api(context).deleteAccount(password);
  } on ApiFailure catch (failure) {
    if (!context.mounted) return;
    _toast(context, failure.messageKey, error: true);
    return;
  }
  if (!context.mounted) return;
  _toast(context, 'settings.account.delete.toast');
  await authCubit.signOut();
}

Future<void> _changePassword(BuildContext context) async {
  final result = await showShadDialog<_PasswordChange>(
    context: context,
    builder: (_) => const _PasswordDialog(),
  );
  if (result == null || !context.mounted) return;
  final authCubit = context.read<AuthCubit>();
  await _run(
    context,
    () => _api(context).changePassword(
      current: result.current,
      next: result.next,
      confirmation: result.confirmation,
    ),
    successKey: 'settings.account.password.updated',
    refresh: false,
  );
  if (!context.mounted) return;
  // The server changes the session when the password changes, so the user
  // signs in again.
  await authCubit.signOut();
}

/// Runs a save. On success it refreshes the account and shows [successKey];
/// on failure it shows the server's message.
Future<void> _run(
  BuildContext context,
  Future<void> Function() save, {
  required String? successKey,
  bool refresh = true,
}) async {
  try {
    await save();
    if (!context.mounted) return;
    if (refresh) await context.read<AuthCubit>().refreshAccount();
    if (!context.mounted) return;
    if (successKey != null) _toast(context, successKey);
  } on ApiFailure catch (failure) {
    if (!context.mounted) return;
    _toast(context, failure.messageKey, error: true);
  }
}

void _toast(BuildContext context, String key, {bool error = false}) {
  final text = Text(AppLocalizations.of(context).t(key));
  ShadToaster.of(context).show(
    error
        ? ShadToast.destructive(description: text)
        : ShadToast(description: text),
  );
}

Future<String?> _askText(
  BuildContext context, {
  required String title,
  required String description,
  required String initial,
  required String action,
  int lines = 1,
}) {
  return showShadDialog<String>(
    context: context,
    builder: (_) => _TextDialog(
      title: title,
      description: description,
      initial: initial,
      action: action,
      lines: lines,
    ),
  );
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({
    required this.title,
    required this.description,
    required this.initial,
    required this.action,
    required this.lines,
  });

  final String title;
  final String description;
  final String initial;
  final String action;
  final int lines;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AmberDialog(
      title: Text(widget.title),
      description: Text(widget.description),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.t('common.cancel')),
        ),
        ShadButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(widget.action),
        ),
      ],
      child: widget.lines == 1
          ? ShadInput(controller: _controller, autofocus: true)
          : ShadTextarea(controller: _controller, minHeight: 96),
    );
  }
}

class _PasswordChange {
  const _PasswordChange(this.current, this.next, this.confirmation);

  final String current;
  final String next;
  final String confirmation;
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirmation = TextEditingController();
  String? _errorKey;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    if (_next.text != _confirmation.text) {
      setState(() => _errorKey = 'settings.account.password.different');
      return;
    }
    Navigator.of(context)
        .pop(_PasswordChange(_current.text, _next.text, _confirmation.text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errorKey = _errorKey;
    return AmberDialog(
      title: Text(l10n.t('settings.account.password.title')),
      description: Text(l10n.t('settings.account.password.description')),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.t('common.cancel')),
        ),
        ShadButton(
          key: const ValueKey('password-submit'),
          onPressed: _submit,
          child: Text(l10n.t('settings.account.password.action')),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ShadInput(
            controller: _current,
            obscureText: true,
            placeholder: Text(
              l10n.t('settings.account.password.current_password'),
            ),
          ),
          const SizedBox(height: 8),
          ShadInput(
            controller: _next,
            obscureText: true,
            placeholder: Text(l10n.t('settings.account.password.new_password')),
          ),
          const SizedBox(height: 8),
          ShadInput(
            controller: _confirmation,
            obscureText: true,
            placeholder: Text(
              l10n.t('settings.account.password.new_password_confirmation'),
            ),
          ),
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

class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog();

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AmberDialog(
      title: Text(l10n.t('settings.account.delete.title')),
      description: Text(l10n.t('settings.account.delete.description')),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.t('common.cancel')),
        ),
        ShadButton.destructive(
          key: const ValueKey('delete-continue'),
          onPressed: () {
            if (_password.text.isNotEmpty) {
              Navigator.of(context).pop(_password.text);
            }
          },
          child: Text(l10n.t('settings.account.delete.action')),
        ),
      ],
      child: ShadInput(
        key: const ValueKey('delete-password'),
        controller: _password,
        obscureText: true,
        placeholder: Text(l10n.t('settings.account.password.current_password')),
      ),
    );
  }
}
