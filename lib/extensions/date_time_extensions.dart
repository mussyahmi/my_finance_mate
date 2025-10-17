import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  String getDateText() {
    DateTime now = DateTime.now();

    if (DateTime(now.year, now.month, now.day, 0, 0) ==
        DateTime(year, month, day, 0, 0)) {
      return 'Today';
    } else if (DateTime(now.year, now.month, now.day - 1, 0, 0) ==
        DateTime(year, month, day, 0, 0)) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, d MMMM yyyy').format(this);
    }
  }
}
