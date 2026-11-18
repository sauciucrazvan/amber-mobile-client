import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
// The emoji package is built on Flutter's own Material widgets, which look up
// Flutter's localizations. material_ui has its own, so the picker gets Flutter's.
// ignore: deprecated_member_use
import 'package:flutter/material.dart' as flutter_material;
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Full emoji picker in a bottom sheet. Resolves to the chosen emoji, or
/// null when dismissed.
Future<String?> showEmojiPicker(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.5,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  l10n.t('conversations.reactions.title'),
                  style: ShadTheme.of(sheetContext).textTheme.large,
                ),
              ),
            ),
            Expanded(
              child: Localizations.override(
                context: sheetContext,
                delegates: [
                  flutter_material.DefaultMaterialLocalizations.delegate,
                ],
                child: EmojiPicker(
                  onEmojiSelected: (_, emoji) =>
                      Navigator.of(sheetContext).pop(emoji.emoji),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
