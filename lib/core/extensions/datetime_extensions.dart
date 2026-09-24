import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  bool isSameDay(DateTime other) => year == other.year && month == other.month && day == other.day;

  DateTime get startOfDay => DateTime(year, month, day);

  String get time => DateFormat('h:mm a').format(this);
  String get shortDate => DateFormat('d MMM').format(this);
  String get fullDate => DateFormat('d MMM yyyy').format(this);
  String get weekday => DateFormat('EEE').format(this);

  /// "Today, 8:42 AM", "Yesterday, 9:05 PM", "Tue, 9:05 PM", "12 Sep, 7:10 AM".
  String get friendly {
    final now = DateTime.now();
    if (isSameDay(now)) return 'Today, $time';
    if (isSameDay(now.subtract(const Duration(days: 1)))) return 'Yesterday, $time';
    if (now.difference(this).inDays < 7) return '$weekday, $time';
    return '$shortDate, $time';
  }

  String get greeting {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

extension MinutesOfDayX on int {
  /// Formats minutes-after-midnight as "8:00 AM".
  String get asTimeOfDay {
    final d = DateTime(2000, 1, 1, this ~/ 60, this % 60);
    return DateFormat('h:mm a').format(d);
  }
}
