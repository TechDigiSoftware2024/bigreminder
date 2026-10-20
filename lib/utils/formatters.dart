import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  /// Indian rupee display: ₹1,40,000 or ₹979.82.
  static String currency(num amount, {int? decimalDigits}) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: decimalDigits ?? _decimalDigits(amount),
    ).format(amount);
  }

  /// Same grouping, without the rupee symbol.
  static String plain(num amount, {int? decimalDigits}) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: decimalDigits ?? _decimalDigits(amount),
    ).format(amount).trim();
  }

  static String currencyOf(Object? raw, {int? decimalDigits}) {
    return currency(parseAmount(raw), decimalDigits: decimalDigits);
  }

  static double parseAmount(Object? raw) {
    if (raw is num) return raw.toDouble();
    final text = raw?.toString().replaceAll(',', '').trim() ?? '';
    return double.tryParse(text) ?? 0;
  }

  static int _decimalDigits(num amount) {
    final value = amount.toDouble();
    if (value.isNaN || value.isInfinite) return 0;
    final paise = (value * 100).round();
    return paise % 100 == 0 ? 0 : 2;
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