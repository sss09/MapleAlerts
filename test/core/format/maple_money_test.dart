import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/core/format/maple_money.dart';

void main() {
  group('MapleMoney.cad', () {
    test('en_CA: leading \$, comma grouping, two decimals', () {
      expect(MapleMoney.cad(1234.56, locale: 'en_CA'), r'$1,234.56');
    });

    test('en_CA: cents:false drops decimals', () {
      expect(MapleMoney.cad(7000, locale: 'en_CA', cents: false), r'$7,000');
    });

    test('en_CA: symbol:false omits the dollar sign', () {
      expect(MapleMoney.cad(1234.56, locale: 'en_CA', symbol: false),
          '1,234.56');
    });

    test('en_CA: negatives render with a leading minus', () {
      expect(MapleMoney.cad(-50, locale: 'en_CA', cents: false), r'-$50');
    });

    test('fr_CA: comma decimal separator and trailing symbol', () {
      final s = MapleMoney.cad(1234.56, locale: 'fr_CA');
      expect(s.contains(','), isTrue, reason: 'fr_CA uses a decimal comma');
      expect(s.endsWith(r'$'), isTrue, reason: 'fr_CA places \$ after');
    });
  });

  group('MapleMoney.cadAuto', () {
    test('drops cents for whole dollar amounts', () {
      expect(MapleMoney.cadAuto(7000, locale: 'en_CA'), r'$7,000');
    });

    test('shows two decimals for fractional amounts', () {
      expect(MapleMoney.cadAuto(1234.5, locale: 'en_CA'), r'$1,234.50');
    });
  });

  group('MapleMoney.cadCompact', () {
    test('compacts thousands and millions', () {
      expect(MapleMoney.cadCompact(1200, locale: 'en_CA'), r'$1.2K');
      expect(MapleMoney.cadCompact(3400000, locale: 'en_CA'), r'$3.4M');
    });

    test('falls back to full format under 1000', () {
      expect(MapleMoney.cadCompact(950, locale: 'en_CA'), r'$950');
    });
  });
}
