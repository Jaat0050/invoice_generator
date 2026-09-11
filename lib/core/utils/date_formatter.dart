import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _standardFormat = DateFormat('dd MMM yyyy'); // e.g. 10 Sep 2026
  static final DateFormat _shortFormat = DateFormat('dd/MM/yyyy'); // e.g. 10/09/2026
  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');

  static String format(DateTime? date) {
    if (date == null) return '';
    return _standardFormat.format(date);
  }

  static String formatShort(DateTime? date) {
    if (date == null) return '';
    return _shortFormat.format(date);
  }

  static String toIso(DateTime? date) {
    if (date == null) return '';
    return _isoFormat.format(date);
  }

  static DateTime? parseIso(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Calculates days remaining or overdue
  static String getDueStatusText(DateTime dueDate, double balanceDue) {
    if (balanceDue <= 0.01) return 'Paid';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final difference = due.difference(today).inDays;

    if (difference < 0) {
      return '${difference.abs()} days overdue';
    } else if (difference == 0) {
      return 'Due today';
    } else {
      return 'Due in $difference days';
    }
  }
}
