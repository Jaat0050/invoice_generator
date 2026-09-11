import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Formats amount in standard Indian Currency notation (e.g. ₹1,25,000.00)
  static String format(num? amount, {bool showSymbol = true}) {
    if (amount == null) return showSymbol ? '₹0.00' : '0.00';
    final formatted = _inrFormatter.format(amount);
    return showSymbol ? formatted : formatted.replaceAll('₹', '').trim();
  }

  /// Compact representation for KPI dashboards (e.g. ₹12.5L, ₹1.2Cr)
  static String formatCompact(num? amount) {
    if (amount == null) return '₹0';
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)} k';
    }
    return format(amount);
  }

  /// Parses string into double safely
  static double parse(String value) {
    final clean = value.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }
}
