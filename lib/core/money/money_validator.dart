import '../storage/app_storage.dart';

/// Validates send / contribute amounts against wallet balance (int kobo).
class MoneyValidator {
  MoneyValidator._();

  /// Returns null if valid, otherwise an English error string.
  static Future<String?> validate(int amountKobo, AppStorage storage) async {
    if (amountKobo <= 0) return 'Amount must be greater than zero';
    final balance = await storage.getBalanceKobo();
    if (amountKobo > balance) return 'Insufficient balance';
    return null;
  }
}
