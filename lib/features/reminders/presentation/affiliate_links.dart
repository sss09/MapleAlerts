import 'package:maple_alerts/utils/constants.dart';

class AffiliateLink {
  final String label;
  final String url;
  const AffiliateLink(this.label, this.url);
}

/// Returns a relevant partner CTA for a category, or null when none applies.
/// Only categories with a genuinely useful, timely partner get a CTA.
AffiliateLink? affiliateForCategory(String categoryId) {
  switch (categoryId) {
    case 'finance':
      return const AffiliateLink('Compare savings & GIC rates', kEqBankUrl);
    case 'home':
      return const AffiliateLink('Compare mortgage rates', kRatehubUrl);
    default:
      return null;
  }
}
