// Institution rate data: HISA and GIC snapshots sourced from the hosted
// data pack. Pure Dart — no Flutter, no network.

/// A single institution's rate offering (HISA or GIC).
class InstitutionRate {
  final String id;
  final String name;
  final String insurance;
  final double rate;
  final int tier;
  final bool hasAffiliate;
  final String? note;

  const InstitutionRate({
    required this.id,
    required this.name,
    required this.rate,
    required this.insurance,
    required this.tier,
    required this.hasAffiliate,
    this.note,
  });

  factory InstitutionRate.fromJson(Map<String, dynamic> j) => InstitutionRate(
        id: j['id'] as String,
        name: j['name'] as String,
        rate: (j['rate'] as num).toDouble(),
        insurance: j['insurance'] as String,
        tier: (j['tier'] as num?)?.toInt() ?? 1,
        hasAffiliate: j['hasAffiliate'] as bool? ?? false,
        note: j['note'] as String?,
      );
}

/// Snapshot of HISA and 1-year GIC rates from the hosted data pack.
class RatesData {
  final String asOf;
  final String disclaimer;
  final List<InstitutionRate> hisa;
  final List<InstitutionRate> gic1yr;

  const RatesData({
    required this.asOf,
    required this.disclaimer,
    required this.hisa,
    required this.gic1yr,
  });

  /// Sentinel returned when the pack carries no rates section.
  static const empty = RatesData(asOf: '', disclaimer: '', hisa: [], gic1yr: []);

  factory RatesData.fromJson(Map<String, dynamic> j) {
    // Return the canonical empty sentinel when the map carries nothing useful,
    // so callers can use `identical(r, RatesData.empty)` as a quick guard.
    if (j.isEmpty) return empty;
    return RatesData(
      asOf: j['asOf'] as String? ?? '',
      disclaimer: j['disclaimer'] as String? ?? '',
      hisa: (j['hisa'] as List?)
              ?.map((e) => InstitutionRate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      gic1yr: (j['gic_1yr'] as List?)
              ?.map((e) => InstitutionRate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Best HISA rate (tier 1 only, highest rate).
  InstitutionRate? get bestHisa => hisa
      .where((r) => r.tier == 1)
      .fold<InstitutionRate?>(
          null, (best, r) => best == null || r.rate > best.rate ? r : best);

  /// Best 1-yr GIC rate.
  InstitutionRate? get bestGic1yr => gic1yr.fold<InstitutionRate?>(
      null, (best, r) => best == null || r.rate > best.rate ? r : best);

  /// The big-bank baseline rate (tier 3, for gap calculation).
  double get bigBankRate => hisa
      .where((r) => r.tier == 3)
      .map((r) => r.rate)
      .fold(0.05, (a, b) => b);
}
