import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Shows a contacts result message in a toast. Contact messages use a
/// `{{user}}` placeholder, filled with [username].
void showContactToast(
  BuildContext context,
  String messageKey, {
  required String username,
  bool isError = false,
}) {
  final text = Text(
    AppLocalizations.of(context).t(messageKey, params: {'user': username}),
  );
  ShadToaster.of(context).show(
    isError
        ? ShadToast.destructive(description: text)
        : ShadToast(description: text),
  );
}
