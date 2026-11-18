import 'package:amber_mobile_client/core/l10n/app_localizations.dart';

/// "now", "5m ago", "3h ago", "2d ago" or "1w ago", like the desktop's
/// `formatRelativeTime`. Empty when there is no time.
String formatRelativeTime(
  AppLocalizations l10n,
  DateTime? time, {
  DateTime? now,
}) {
  if (time == null) return '';

  final diff = (now ?? DateTime.now()).toUtc().difference(time.toUtc());
  final minutes = diff.inMinutes;
  if (minutes < 1) return l10n.t('calls.history.relative.now');
  if (minutes < 60) {
    return l10n.t(
      'calls.history.relative.minutesAgo',
      params: {'count': minutes},
    );
  }

  final hours = minutes ~/ 60;
  if (hours < 24) {
    return l10n.t('calls.history.relative.hoursAgo', params: {'count': hours});
  }

  final days = hours ~/ 24;
  if (days < 7) {
    return l10n.t('calls.history.relative.daysAgo', params: {'count': days});
  }

  return l10n.t(
    'calls.history.relative.weeksAgo',
    params: {'count': days ~/ 7},
  );
}
