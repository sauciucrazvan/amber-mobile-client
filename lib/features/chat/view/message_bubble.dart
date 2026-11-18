import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/features/chat/data/chat_models.dart';
import 'package:amber_mobile_client/features/chat/view/image_preview.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Local calendar day, used to group messages.
DateTime dayOf(DateTime? time) {
  final local = (time ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))
      .toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// `2026-11-18`. Localized dates need `intl`, which isn't a dependency yet.
String formatDay(DateTime day) {
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$date';
}

String formatTime(DateTime? time) {
  if (time == null) return '';
  final local = time.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// A divider between days in the message list.
class DaySeparator extends StatelessWidget {
  const DaySeparator({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: ShadSeparator.horizontal()),
          const SizedBox(width: 8),
          Text(formatDay(day), style: theme.textTheme.muted),
          const SizedBox(width: 8),
          const Expanded(child: ShadSeparator.horizontal()),
        ],
      ),
    );
  }
}

/// One message. Mine align right and use the primary colour.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onLongPress,
    this.onReactionTap,
  });

  final ChatMessage message;
  final bool isMine;

  /// Opens the message actions (reply, react, edit, delete).
  final VoidCallback? onLongPress;

  /// Opens the reactions panel for [emoji].
  final ValueChanged<String>? onReactionTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final background = isMine
        ? theme.colorScheme.primary
        : theme.colorScheme.muted;
    final foreground = isMine
        ? theme.colorScheme.primaryForeground
        : theme.colorScheme.foreground;
    final body = _body(context, foreground);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.replyTo case final reply?)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: foreground.withAlpha(120),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      reply.text ?? '',
                      style: theme.textTheme.small.copyWith(
                        color: foreground.withAlpha(180),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: foreground),
                    child: body,
                  ),
                ),
                if (message.reactions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final reaction in message.reactions)
                        GestureDetector(
                          onTap: onReactionTap == null
                              ? null
                              : () => onReactionTap!(reaction.emoji),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: foreground.withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${reaction.emoji} ${reaction.count}',
                              style: theme.textTheme.small,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  [
                    formatTime(message.createdAt),
                    if (message.isEdited) l10n.t('conversations.edited'),
                    if (isMine && message.seen) 'seen',
                  ].join(' · '),
                  style: theme.textTheme.small.copyWith(
                    color: foreground.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, Color foreground) {
    final file = message.file;
    if (file != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _FileAttachment(file: file, foreground: foreground),
          if (message.text case final caption? when caption.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(caption),
          ],
        ],
      );
    }
    if (message.type == 'log') {
      return Text(
        message.text ?? '',
        style: const TextStyle(fontStyle: FontStyle.italic),
      );
    }
    return Text(message.text ?? '');
  }
}

/// An attachment inside a bubble. Images show a preview that opens full
/// screen. Other files show their name and size.
class _FileAttachment extends StatelessWidget {
  const _FileAttachment({required this.file, required this.foreground});

  final ChatFile file;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    if (file.isImage) {
      return GestureDetector(
        onTap: () =>
            showImagePreview(context, url: file.url, filename: file.filename),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240, maxHeight: 320),
            child: Image.network(
              file.url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fileRow(context),
            ),
          ),
        ),
      );
    }
    return _fileRow(context);
  }

  Widget _fileRow(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.file, size: 18, color: foreground),
        const SizedBox(width: 8),
        Flexible(child: Text(file.filename, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Text(formatFileSize(file.size), style: theme.textTheme.small),
      ],
    );
  }
}

/// `512 B`, `240 KB` or `3.2 MB`.
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
