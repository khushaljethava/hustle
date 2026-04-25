import 'package:intl/intl.dart';

class Formatters {
  static String formatCurrency(double amount, String currency) {
    final symbols = {
      'USD': '\$', 'EUR': '€', 'GBP': '£', 'CAD': 'CA\$',
      'AUD': 'A\$', 'JPY': '¥', 'INR': '₹', 'BRL': 'R\$',
    };
    final symbol = symbols[currency] ?? currency;
    final formatted = NumberFormat('#,##0.00').format(amount);
    return '$symbol$formatted';
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }

  static String formatDurationHours(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  static String formatDurationDecimal(Duration duration) {
    final hours = duration.inMinutes / 60;
    return hours.toStringAsFixed(1) + 'h';
  }

  static String formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('MMM d').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  static String formatMonth(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return formatDate(date);
  }

  static String formatRelativeDue(DateTime due) {
    final now = DateTime.now();
    final diff = due.difference(now);
    if (diff.isNegative) {
      final days = diff.inDays.abs();
      if (days == 0) return 'Due today';
      return 'Overdue by ${days}d';
    }
    if (diff.inDays == 0) return 'Due today';
    if (diff.inDays == 1) return 'Due tomorrow';
    if (diff.inDays < 7) return 'Due in ${diff.inDays}d';
    return 'Due ${formatDateShort(due)}';
  }

  static String invoiceNumber(int id) {
    return 'INV-${id.toString().padLeft(4, '0')}';
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
