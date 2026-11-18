import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/features/chat/data/chat_models.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Lists who reacted to [message] with each emoji. The current user's own
/// reaction can be added or removed from here.
///
/// [nameOf] turns a user id into a name. [onToggle] adds the current user's
/// reaction when it's absent and removes it when present.
Future<void> showReactionsPanel(
  BuildContext context, {
  required ChatMessage message,
  required int myUserId,
  required String Function(int userId) nameOf,
  required Future<void> Function(String emoji) onToggle,
}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.t('conversations.reactions.title'),
              style: ShadTheme.of(sheetContext).textTheme.large,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.t('conversations.reactions.hint'),
              style: ShadTheme.of(sheetContext).textTheme.muted,
            ),
            const SizedBox(height: 12),
            for (final reaction in message.reactions)
              _ReactionRow(
                reaction: reaction,
                reactedByMe: reaction.isReactedBy(myUserId),
                names: [for (final id in reaction.userIds) nameOf(id)],
                onToggle: () async {
                  Navigator.of(sheetContext).pop();
                  await onToggle(reaction.emoji);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

class _ReactionRow extends StatelessWidget {
  const _ReactionRow({
    required this.reaction,
    required this.reactedByMe,
    required this.names,
    required this.onToggle,
  });

  final MessageReaction reaction;
  final bool reactedByMe;
  final List<String> names;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(reaction.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              names.join(', '),
              style: theme.textTheme.muted,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ShadButton.outline(
            size: ShadButtonSize.sm,
            onPressed: onToggle,
            child: Text(
              l10n.t(
                reactedByMe
                    ? 'conversations.reactions.remove'
                    : 'conversations.reactions.add',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
