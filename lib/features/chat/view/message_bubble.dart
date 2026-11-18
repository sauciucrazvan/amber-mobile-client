import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/core/l10n/dates.dart';
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

/// The text of a log message, such as a call event. Call events use the
/// `calls.logs.*` translations, and fall back to the stored text.
String logMessageText(AppLocalizations l10n, Map<String, dynamic> content) {
  final text = content['text'] as String?;
  final event = content['event'];
  if (event is String && event.startsWith('call.')) {
    final key = 'calls.logs.${event.substring('call.'.length)}';
    final label = l10n.t(key);
    // `t` returns the key itself when no translation exists.
    if (label != key) return label;
    return text ?? l10n.t('contacts.last_message.call');
  }
  return text ?? '';
}

/// A log entry, centred between two thin lines, like the desktop's separator.
class LogSeparator extends StatelessWidget {
  const LogSeparator({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: ShadSeparator.horizontal()),
          const SizedBox(width: 8),
          Text(
            logMessageText(l10n, message.content),
            style: theme.textTheme.small.copyWith(fontSize: 12),
          ),
          const SizedBox(width: 8),
          Text(
            formatTime(message.createdAt),
            style: theme.textTheme.small.copyWith(
              fontSize: 10,
              color: theme.colorScheme.mutedForeground,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: ShadSeparator.horizontal()),
        ],
      ),
    );
  }
}

/// The date above each day's first message, in a centred outline badge, as
/// on the desktop.
class DaySeparator extends StatelessWidget {
  const DaySeparator({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context).localeCode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: ShadBadge.outline(child: Text(formatLongDate(locale, day))),
      ),
    );
  }
}

/// How many reaction emoji the pill shows before "+N", by message length,
/// as on the desktop.
int visibleReactionCount({required String? text, required bool hasFile}) {
  if (hasFile) return 3;
  final length = text?.length ?? 0;
  if (length < 15) return 1;
  if (length < 40) return 2;
  if (length < 80) return 3;
  return 4;
}

/// One message. Mine align right and use the light tint, others use the muted
/// colour.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.myUserId,
    required this.nameOf,
    this.onLongPress,
    this.onReactionTap,
  });

  final ChatMessage message;
  final bool isMine;

  /// The current user, so a reply to their own message reads "You".
  final int myUserId;

  /// Turns a user id into a name, for the reply quote.
  final String Function(int userId) nameOf;

  /// Opens the message actions (reply, react, edit, delete).
  final VoidCallback? onLongPress;

  /// Opens the reactions panel.
  final VoidCallback? onReactionTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context);
    // Matches the desktop: own messages use a light tint of the primary
    // colour, others use the muted colour at 80% with primary text.
    final dark = theme.brightness == Brightness.dark;
    final background = isMine
        ? (dark ? const Color(0xFF2E2E2E) : const Color(0xFFE8E8E8))
        : theme.colorScheme.muted.withAlpha(204);
    final foreground = isMine
        ? theme.colorScheme.foreground
        : theme.colorScheme.primary;
    final hasReactions = message.reactions.isNotEmpty;

    final bubble = GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.replyTo case final reply?)
              _ReplyQuote(
                reply: reply,
                authorName: reply.senderId == myUserId
                    ? l10n.t('conversations.you')
                    : nameOf(reply.senderId),
              ),
            _body(context, foreground),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.isEdited) ...[
                  Text(
                    l10n.t('conversations.edited'),
                    style: _metaStyle(theme, foreground),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  formatTime(message.createdAt),
                  style: _metaStyle(theme, foreground),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  // Blue double check when read, grey single check otherwise,
                  // as on the desktop.
                  message.seen
                      ? const Icon(
                          LucideIcons.checkCheck,
                          size: 12,
                          color: Color(0xFF60A5FA),
                        )
                      : Icon(
                          LucideIcons.check,
                          size: 12,
                          color: foreground.withAlpha(180),
                        ),
                ],
              ],
            ),
          ],
        ),
      ),
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              bubble,
              if (hasReactions)
                // Laid out below the bubble, then moved up so it overlaps the
                // bottom edge, as on the desktop. Transform keeps the tap area
                // where the pill is drawn.
                Transform.translate(
                  offset: const Offset(0, -6),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: isMine ? 8 : 0,
                      right: isMine ? 0 : 8,
                    ),
                    child: _ReactionPill(
                      key: ValueKey('reactions-${message.id}'),
                      message: message,
                      visible: visibleReactionCount(
                        text: message.text,
                        hasFile: message.file != null,
                      ),
                      onTap: onReactionTap,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _metaStyle(ShadThemeData theme, Color foreground) => theme
      .textTheme
      .small
      .copyWith(fontSize: 11, color: foreground.withAlpha(180));

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
            Text(caption, style: TextStyle(color: foreground)),
          ],
        ],
      );
    }
    return Text(message.text ?? '', style: TextStyle(color: foreground));
  }
}

/// The message being replied to, styled like the desktop's quote: a thick
/// left border on a faint background, with the author and two lines of text.
class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({required this.reply, required this.authorName});

  final ReplyTo reply;
  final String authorName;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final muted = theme.colorScheme.mutedForeground;
    final isFile = reply.type == 'file';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: muted.withAlpha(26),
        border: Border(left: BorderSide(color: muted.withAlpha(77), width: 4)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(2),
          bottomLeft: Radius.circular(2),
          topRight: Radius.circular(6),
          bottomRight: Radius.circular(6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            authorName.isEmpty ? l10n.t('conversations.you') : authorName,
            style: theme.textTheme.small.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
          const SizedBox(height: 2),
          if (isFile)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.paperclip, size: 14, color: muted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    l10n.t('conversations.files.attachment'),
                    style: theme.textTheme.small.copyWith(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else
            Text(
              reply.text ?? '',
              style: theme.textTheme.small.copyWith(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

/// The emoji pill that hangs over the bottom edge of a bubble. It shows the
/// reaction emoji only, with "+N" when there are more than fit.
class _ReactionPill extends StatelessWidget {
  const _ReactionPill({
    super.key,
    required this.message,
    required this.visible,
    required this.onTap,
  });

  final ChatMessage message;
  final int visible;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final reactions = message.reactions;
    final shown = reactions.take(visible);
    final hidden = reactions.length - visible;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.muted,
          borderRadius: BorderRadius.circular(999),
          // The desktop's ring-3 ring-card: separates the pill from the bubble.
          border: Border.all(color: theme.colorScheme.card, width: 3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final reaction in shown)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Text(
                  reaction.emoji,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            if (hidden > 0)
              Text(
                '+$hidden',
                style: theme.textTheme.small.copyWith(fontSize: 12),
              ),
          ],
        ),
      ),
    );
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
