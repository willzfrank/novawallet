import 'package:intl/intl.dart';

/// All money is stored/computed as int kobo. Display conversion only.
class Money {
  Money._();

  static final NumberFormat _amount = NumberFormat('#,##0.00', 'en');
  static final NumberFormat _intGroup = NumberFormat('#,##0', 'en');

  /// Format kobo int for display. Only place that divides by 100.
  static String formatKobo(int koboAmount) {
    return '₦${_amount.format(koboAmount / 100)}';
  }

  /// Live TextField formatting: `2000` → `2,000`, `2000.5` → `2,000.5`.
  /// Keeps a trailing `.` while the user is typing decimals.
  static String formatNairaTyping(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) return '';

    final buf = StringBuffer();
    var seenDot = false;
    var decimals = 0;
    for (final unit in cleaned.codeUnits) {
      final c = String.fromCharCode(unit);
      if (c == '.') {
        if (seenDot) continue;
        seenDot = true;
        buf.write(c);
        continue;
      }
      if (seenDot) {
        if (decimals >= 2) continue;
        decimals++;
      }
      buf.write(c);
    }

    final raw = buf.toString();
    if (raw.isEmpty) return '';

    final dot = raw.indexOf('.');
    final hasDot = dot >= 0;
    final intRaw = hasDot ? raw.substring(0, dot) : raw;
    final frac = hasDot ? raw.substring(dot + 1) : null;

    final intDigits = intRaw.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final grouped = _intGroup.format(
      int.parse(intDigits.isEmpty ? '0' : intDigits),
    );

    if (!hasDot) return grouped;
    if (frac == null || frac.isEmpty) return '$grouped.';
    return '$grouped.$frac';
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
