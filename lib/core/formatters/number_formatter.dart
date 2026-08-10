import 'package:intl/intl.dart';

class NumberFormatter {
  /// Formats an amount using spaces as a thousand separator.
  /// Example: 200000.00 becomes 200 000.00
  static String formatAmount(double amount) {
    // We use a custom pattern that outputs commas for thousands, 
    // then manually replace the comma with a space to guarantee the requested format
    // regardless of the underlying locale's default symbol for thousands.
    final formatter = NumberFormat.currency(customPattern: '#,##0.00', symbol: '');
    return formatter.format(amount).replaceAll(',', ' ').trim();
  }
}
