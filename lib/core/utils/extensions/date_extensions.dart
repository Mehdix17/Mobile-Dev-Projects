import 'package:intl/intl.dart';

extension DateExtensions on DateTime {
  /// Check if this date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if this date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if this date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Check if this date is in the current week
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Get the start of the day
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get the end of the day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Get the start of the week (Monday)
  DateTime get startOfWeek {
    return subtract(Duration(days: weekday - 1)).startOfDay;
  }

  /// Get the end of the week (Sunday)
  DateTime get endOfWeek {
    return add(Duration(days: 7 - weekday)).endOfDay;
  }

  /// Get the start of the month
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Get the end of the month
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59, 999);

  /// Format as relative date (Today, Yesterday, or date)
  String toRelativeString() {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (isTomorrow) return 'Tomorrow';

    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays < 7 && difference.inDays > 0) {
      return DateFormat.EEEE().format(this); // Day name
    }

    if (year == now.year) {
      return DateFormat.MMMd().format(this); // "Jan 15"
    }

    return DateFormat.yMMMd().format(this); // "Jan 15, 2024"
  }

  /// Format as short date
  String toShortString() {
    return DateFormat.MMMd().format(this);
  }

  /// Format as full date
  String toFullString() {
    return DateFormat.yMMMMd().format(this);
  }

  /// Format as time
  String toTimeString() {
    return DateFormat.jm().format(this);
  }

  /// Format as date and time
  String toDateTimeString() {
    return DateFormat.yMMMd().add_jm().format(this);
  }

  /// Get days until this date
  int daysUntil() {
    return startOfDay.difference(DateTime.now().startOfDay).inDays;
  }

  /// Get days since this date
  int daysSince() {
    return DateTime.now().startOfDay.difference(startOfDay).inDays;
  }

  /// Check if dates are the same day
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

extension DurationExtensions on Duration {
  /// Format duration as "Xh Ym" or "Ym Zs"
  String toReadableString() {
    if (inHours > 0) {
      final hours = inHours;
      final minutes = inMinutes % 60;
      if (minutes == 0) return '${hours}h';
      return '${hours}h ${minutes}m';
    }

    if (inMinutes > 0) {
      final minutes = inMinutes;
      final seconds = inSeconds % 60;
      if (seconds == 0) return '${minutes}m';
      return '${minutes}m ${seconds}s';
    }

    return '${inSeconds}s';
  }

  /// Format duration as "X:XX" (minutes:seconds)
  String toTimerString() {
    final minutes = inMinutes;
    final seconds = inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format duration as "XX:XX" (minutes:seconds) with leading zero
  String toTimerStringPadded() {
    final minutes = inMinutes;
    final seconds = inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
