import 'package:flutter_test/flutter_test.dart';
import 'package:nova_wallet/core/money/money.dart';

void main() {
  group('Money kobo', () {
    test('₦1,500.75 → 150075 kobo', () {
      expect(Money.nairaStringToKobo('1500.75'), 150075);
      expect(Money.nairaStringToKobo('1,500.75'), 150075);
    });

    test('format never used for math', () {
      expect(Money.formatKobo(150075), contains('1,500.75'));
    });

    test('rejects invalid', () {
      expect(Money.nairaStringToKobo('abc'), isNull);
      expect(Money.nairaStringToKobo('12.345'), isNull);
    });
  });
}
