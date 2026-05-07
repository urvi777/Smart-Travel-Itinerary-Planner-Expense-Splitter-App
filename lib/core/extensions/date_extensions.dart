import 'package:intl/intl.dart';

/// Convenience extensions on [DateTime].
extension DateTimeExtensions on DateTime {
  /// Format as "Mon, 15 Jan 2025"
  String get formatted => DateFormat('EEE, d MMM yyyy').format(this);

  /// Format as "15 Jan"
  String get shortFormatted => DateFormat('d MMM').format(this);

  /// Format as "15 Jan 2025"
  String get mediumFormatted => DateFormat('d MMM yyyy').format(this);

  /// Format as "3:30 PM"
  String get timeFormatted => DateFormat('h:mm a').format(this);

  /// Format as "Jan 2025"
  String get monthYear => DateFormat('MMM yyyy').format(this);

  /// Check if same calendar day as [other].
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Strip the time component, returning midnight of this date.
  DateTime get dateOnly => DateTime(year, month, day);

  /// Number of full days between this date and [other].
  int daysBetween(DateTime other) {
    return dateOnly.difference(other.dateOnly).inDays.abs();
  }
}
