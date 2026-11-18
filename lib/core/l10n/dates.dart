import 'package:intl/intl.dart';

/// A full date in the app's language, like the desktop's date dividers:
/// "November 18, 2026" in English.
String formatLongDate(String locale, DateTime time) =>
    DateFormat.yMMMMd(locale).format(time.toLocal());

/// Month and year, like the desktop's "Member since": "January 2026".
String formatMonthYear(String locale, DateTime? time) =>
    time == null ? '' : DateFormat.yMMMM(locale).format(time.toLocal());
