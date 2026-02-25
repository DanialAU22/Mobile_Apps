import 'package:intl/intl.dart';

String generateId() {
  // Simple, collision-resistant enough for offline app.
  return DateTime.now().microsecondsSinceEpoch.toString();
}

String formatDate(DateTime? date) {
  if (date == null) return 'No date';
  return DateFormat.yMMMd().format(date);
}

String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return 'No date';
  return DateFormat.yMMMd().add_Hm().format(dateTime);
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

