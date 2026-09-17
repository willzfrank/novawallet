import 'package:intl/intl.dart';

/// All money is stored/computed as int kobo. Display conversion only.
class Money {
  Money._();

  static final NumberFormat _amount = NumberFormat('#,##0.00', 'en');

  /// Format kobo int for display. Only place that divides by 100.
  static String formatKobo(int koboAmount) {
    return '₦${_amount.format(koboAmount / 100)}';
  }

  /// Parse Naira string (e.g. "1500.75") → kobo int. Rejects invalid input.
  static int? nairaStringToKobo(String input) {
    final cleaned = input.trim().replaceAll(',', '');
    if (cleaned.isEmpty) return null;
    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(cleaned);
    if (match == null) return null;
    final naira = int.parse(match.group(1)!);
    final frac = match.group(2);
    final koboPart = frac == null
        ? 0
        : int.parse(frac.padRight(2, '0'));
    return (naira * 100) + koboPart;
  }

  static int nairaToKobo(int naira) => naira * 100;
}
