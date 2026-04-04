import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  /// 💰 CURRENCY FORMAT (₹)
  static String currency(num amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// 💰 SHORT AMOUNT (K, L, Cr)
  static String shortAmount(num amount) {
    if (amount >= 10000000) {
      return "${(amount / 10000000).toStringAsFixed(1)}Cr";
    } else if (amount >= 100000) {
      return "${(amount / 100000).toStringAsFixed(1)}L";
    } else if (amount >= 1000) {
      return "${(amount / 1000).toStringAsFixed(1)}K";
    }
    return amount.toString();
  }

  /// 📅 DATE FORMAT
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// 📅 DATE + TIME
  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  /// ⏱️ RELATIVE TIME (Today, Yesterday)
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";
    return formatDate(date);
  }
}