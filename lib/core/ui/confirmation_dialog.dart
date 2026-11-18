import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Asks the user to confirm an action, like the desktop's `ConfirmationDialog`.
///
/// Resolves to true only when the user taps the confirm button. Cancel,
/// tapping outside and back all resolve to false. Set [destructive] for
/// actions that remove or hide something, so the confirm button is red.
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmText,
  bool destructive = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showShadDialog<bool>(
    context: context,
    builder: (dialogContext) => ShadDialog.alert(
      title: Text(title),
      description: Text(description),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.t('common.cancel')),
        ),
        destructive
            ? ShadButton.destructive(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(confirmText),
              )
            : ShadButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(confirmText),
              ),
      ],
    ),
  );
  return confirmed ?? false;
}
