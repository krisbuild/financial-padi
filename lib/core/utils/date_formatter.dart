import 'package:intl/intl.dart';

String formatShortDate(DateTime date) => DateFormat('MMM d, y').format(date);

String formatDayMonth(DateTime date) => DateFormat('MMM d').format(date);

String formatMonthYear(DateTime date) => DateFormat('MMMM y').format(date);

String formatRelativeDueDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(date.year, date.month, date.day);
  final diff = due.difference(today).inDays;

  if (diff == 0) return 'Due today';
  if (diff == 1) return 'Due tomorrow';
  if (diff < 0) return '${-diff}d overdue';
  if (diff <= 30) return 'Due in $diff days';
  return 'Due ${formatShortDate(date)}';
}
