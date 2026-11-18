import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/ui/confirmation_dialog.dart';
import 'package:amber_mobile_client/features/auth/bloc/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Asks before signing out, as the desktop does. Signs out only on confirm.
Future<void> confirmAndSignOut(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final cubit = context.read<AuthCubit>();
  final confirmed = await showConfirmationDialog(
    context,
    title: l10n.t('settings.account.signOut.title'),
    description: l10n.t('settings.account.signOut.description'),
    confirmText: l10n.t('settings.account.signOut.action'),
  );
  if (confirmed) await cubit.signOut();
}
