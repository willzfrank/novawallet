import 'package:flutter/services.dart';

import 'money.dart';

/// Live thousands separators for Naira amount fields (`40000` → `40,000`).
class NairaThousandsFormatter extends TextInputFormatter {
  const NairaThousandsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = Money.formatNairaTyping(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
