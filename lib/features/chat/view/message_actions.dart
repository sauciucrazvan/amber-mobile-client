import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/features/chat/data/chat_models.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum MessageAction { reply, moreReactions, edit, saveAs, delete }

/// Quick reactions, in the desktop's order: like, love, smile, laugh.
const quickReactions = ['👍', '❤️', '😊', '😂'];

/// Actions for a long-pressed message: quick reactions, then reply, and for
/// the current user's own messages, edit and delete.
///
/// Returns the chosen [MessageAction], or null. A reaction is passed to
/// [onReact] and does not return an action.
Future<MessageAction?> showMessageActions(
  BuildContext context, {
  required ChatMessage message,
  required bool isMine,
  required ValueChanged<String> onReact,
}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<MessageAction>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final emoji in quickReactions)
                  ShadButton.ghost(
                    width: 44,
                    height: 44,
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      onReact(emoji);
                    },
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                // Opens the full picker, like the chevron on the desktop.
                Tooltip(
                  message: l10n.t('conversations.reactions.more'),
                  child: ShadIconButton.ghost(
                    key: const ValueKey('more-reactions'),
                    width: 44,
                    height: 44,
                    padding: EdgeInsets.zero,
                    icon: const Icon(LucideIcons.chevronRight),
                    onPressed: () =>
                        Navigator.of(sheetContext)
                            .pop(MessageAction.moreReactions),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ShadButton.ghost(
              onPressed: () =>
                  Navigator.of(sheetContext).pop(MessageAction.reply),
              child: Text(l10n.t('conversations.actions.reply')),
            ),
            if (message.type == 'file')
              ShadButton.ghost(
                key: const ValueKey('save-as'),
                onPressed: () =>
                    Navigator.of(sheetContext).pop(MessageAction.saveAs),
                child: Text(l10n.t('conversations.actions.save_as')),
              ),
            if (isMine && message.type == 'text')
              ShadButton.ghost(
                onPressed: () =>
                    Navigator.of(sheetContext).pop(MessageAction.edit),
                child: Text(l10n.t('conversations.actions.edit')),
              ),
            if (isMine)
              ShadButton.ghost(
                onPressed: () =>
                    Navigator.of(sheetContext).pop(MessageAction.delete),
                child: Text(l10n.t('conversations.actions.delete')),
              ),
          ],
        ),
      ),
    ),
  );
}
