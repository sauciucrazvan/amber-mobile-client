import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/network/api_failure.dart';
import 'package:amber_mobile_client/core/ui/amber_dialog.dart';
import 'package:amber_mobile_client/features/contacts/bloc/contacts_cubit.dart';
import 'package:amber_mobile_client/features/contacts/view/contact_feedback.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Sends a friend request by username or email.
Future<void> showAddContactDialog(BuildContext context) {
  final cubit = context.read<ContactsCubit>();
  return showShadDialog<void>(
    context: context,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _AddContactDialog()),
  );
}

class _AddContactDialog extends StatefulWidget {
  const _AddContactDialog();

  @override
  State<_AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<_AddContactDialog> {
  final _identifier = TextEditingController();
  String? _errorText;
  bool _submitting = false;

  @override
  void dispose() {
    _identifier.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final identifier = _identifier.text.trim();
    if (identifier.isEmpty) return;

    setState(() {
      _errorText = null;
      _submitting = true;
    });
    try {
      await context.read<ContactsCubit>().sendRequest(identifier);
      if (!mounted) return;
      Navigator.of(context).pop();
      showContactToast(context, 'contacts.requested', username: identifier);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(
        () => _errorText = l10n.t(
          failure.messageKey,
          params: {'user': identifier},
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errorText = _errorText;

    return AmberDialog(
      title: Text(l10n.t('contacts.add.title')),
      description: Text(l10n.t('contacts.add.description')),
      actions: [
        ShadButton(
          onPressed: _submitting ? null : _submit,
          child: Text(l10n.t('contacts.add.action')),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errorText != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShadAlert.destructive(description: Text(errorText)),
            ),
          ShadInput(
            controller: _identifier,
            placeholder: Text(l10n.t('contacts.add.identifier')),
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            enabled: !_submitting,
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
    );
  }
}
