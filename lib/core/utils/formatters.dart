import 'package:intl/intl.dart';

/// Shared display formatters for currency, dates, and relative time.
class Formatters {
  Formatters._();

  static final _peso = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);
  static final _dateShort = DateFormat('MMM d, y');
  static final _dateTime = DateFormat('MMM d, y • h:mm a');
  static final _time = DateFormat('h:mm a');

  static String peso(num amount) => _peso.format(amount);

  static String dateShort(DateTime date) => _dateShort.format(date);

  static String dateTime(DateTime date) => _dateTime.format(date);

  static String time(DateTime date) => _time.format(date);

  static String relative(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return dateShort(date);
  }
}
