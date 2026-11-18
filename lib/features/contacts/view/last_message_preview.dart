import 'package:amber_mobile_client/core/l10n/app_localizations.dart';
import 'package:amber_mobile_client/features/contacts/data/contact_models.dart';

const _callLogPrefix = 'call.';

/// One-line preview of a contact's last message, as the desktop shows it.
/// Messages the current user sent get a "You: " prefix.
String lastMessagePreview(
  AppLocalizations l10n,
  LastMessage? message, {
  required int? myUserId,
}) {
  if (message == null) return '';

  final prefix = myUserId != null && message.senderId == myUserId
      ? '${l10n.t('conversations.you')}: '
      : '';
  final content = message.content;

  switch (message.type) {
    case 'text':
      final text = message.text?.trim() ?? '';
      return text.isEmpty ? '' : '$prefix$text';
    case 'file':
      final name =
          content['filename'] ?? content['file_name'] ?? content['name'];
      final label = name is String && name.isNotEmpty
          ? name
          : l10n.t('contacts.last_message.attachment');
      return '$prefix$label';
    case 'log':
      final event = content['event'];
      if (event is String && event.startsWith(_callLogPrefix)) {
        final key = 'calls.logs.${event.substring(_callLogPrefix.length)}';
        final label = l10n.t(key);
        // `t` returns the key itself when no translation exists.
        final fallback =
            (content['text'] as String?) ??
            l10n.t('contacts.last_message.call');
        return '$prefix${label == key ? fallback : label}';
      }
      final text = message.text?.trim() ?? '';
      return text.isEmpty ? '' : '$prefix$text';
    default:
      return '$prefix${l10n.t('contacts.last_message.unknown')}';
  }
}
