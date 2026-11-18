import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum LegalDocument { terms, privacy }

/// Shows the Terms & Conditions or the Privacy Policy.
Future<void> showLegalDialog(BuildContext context, LegalDocument document) {
  final l10n = AppLocalizations.of(context);
  final key = 'legal.${document.name}';

  return showShadDialog<void>(
    context: context,
    builder: (context) => ShadDialog(
      title: Text(l10n.t('$key.title')),
      description: Text(l10n.t('$key.description')),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.5,
        ),
        child: SingleChildScrollView(
          // The shared locale files store line breaks as a literal "\n".
          child: Text(l10n.t('$key.content').replaceAll(r'\n', '\n')),
        ),
      ),
    ),
  );
}
