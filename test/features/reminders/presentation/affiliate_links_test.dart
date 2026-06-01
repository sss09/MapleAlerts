import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/features/reminders/presentation/affiliate_links.dart';

void main() {
  test('finance + home get a partner CTA, others do not', () {
    expect(affiliateForCategory('finance'), isNotNull);
    expect(affiliateForCategory('finance')!.url, isNotEmpty);
    expect(affiliateForCategory('home'), isNotNull);
    expect(affiliateForCategory('bills'), isNull);
    expect(affiliateForCategory('health'), isNull);
  });
}
