import 'province.dart';

/// The user's financial inputs that the engine's rules read from.
///
/// Grows by adding fields here — NOT by scattering prefs keys across the app.
/// Pure Dart; JSON (de)serialization lives here so there is one place that
/// knows the shape.
class MoneyProfile {
  /// Four-digit year of birth, used to derive TFSA eligibility (age 18) and
  /// RRSP eligibility (must convert to a RRIF at 71).
  final int? birthYear;

  /// Total amount the user has ever contributed to their TFSA, in dollars.
  final double? tfsaContributed;

  /// Province/territory of residence — selects provincial tax brackets.
  final Province? province;

  /// Annual (taxable) income in dollars, used to estimate the marginal rate.
  final double? annualIncome;

  /// RRSP deduction limit from the user's CRA Notice of Assessment.
  final double? rrspDeductionLimit;

  /// Amount contributed against the current RRSP deduction limit, in dollars.
  final double? rrspContributed;

  /// Number of children under 6 (for the Canada Child Benefit).
  final int? kidsUnder6;

  /// Number of children aged 6 to 17 (for the Canada Child Benefit).
  final int? kids6to17;

  /// Adjusted family net income (both spouses) — the CCB phase-out basis.
  /// Distinct from [annualIncome] (the individual figure used for marginal rate).
  final double? familyNetIncome;

  /// Principal of a GIC the user is tracking, in dollars.
  final double? gicAmount;

  /// Maturity date of the tracked GIC.
  final DateTime? gicMaturityDate;

  const MoneyProfile({
    this.birthYear,
    this.tfsaContributed,
    this.province,
    this.annualIncome,
    this.rrspDeductionLimit,
    this.rrspContributed,
    this.kidsUnder6,
    this.kids6to17,
    this.familyNetIncome,
    this.gicAmount,
    this.gicMaturityDate,
  });

  static const empty = MoneyProfile();

  MoneyProfile copyWith({
    int? birthYear,
    double? tfsaContributed,
    Province? province,
    double? annualIncome,
    double? rrspDeductionLimit,
    double? rrspContributed,
    int? kidsUnder6,
    int? kids6to17,
    double? familyNetIncome,
    double? gicAmount,
    DateTime? gicMaturityDate,
    bool clearBirthYear = false,
    bool clearTfsaContributed = false,
    bool clearProvince = false,
    bool clearAnnualIncome = false,
    bool clearRrspDeductionLimit = false,
    bool clearRrspContributed = false,
    bool clearKidsUnder6 = false,
    bool clearKids6to17 = false,
    bool clearFamilyNetIncome = false,
    bool clearGicAmount = false,
    bool clearGicMaturityDate = false,
  }) {
    return MoneyProfile(
      birthYear: clearBirthYear ? null : (birthYear ?? this.birthYear),
      tfsaContributed:
          clearTfsaContributed ? null : (tfsaContributed ?? this.tfsaContributed),
      province: clearProvince ? null : (province ?? this.province),
      annualIncome:
          clearAnnualIncome ? null : (annualIncome ?? this.annualIncome),
      rrspDeductionLimit: clearRrspDeductionLimit
          ? null
          : (rrspDeductionLimit ?? this.rrspDeductionLimit),
      rrspContributed: clearRrspContributed
          ? null
          : (rrspContributed ?? this.rrspContributed),
      kidsUnder6: clearKidsUnder6 ? null : (kidsUnder6 ?? this.kidsUnder6),
      kids6to17: clearKids6to17 ? null : (kids6to17 ?? this.kids6to17),
      familyNetIncome: clearFamilyNetIncome
          ? null
          : (familyNetIncome ?? this.familyNetIncome),
      gicAmount: clearGicAmount ? null : (gicAmount ?? this.gicAmount),
      gicMaturityDate: clearGicMaturityDate
          ? null
          : (gicMaturityDate ?? this.gicMaturityDate),
    );
  }

  Map<String, dynamic> toJson() => {
        if (birthYear != null) 'birthYear': birthYear,
        if (tfsaContributed != null) 'tfsaContributed': tfsaContributed,
        if (province != null) 'province': province!.code,
        if (annualIncome != null) 'annualIncome': annualIncome,
        if (rrspDeductionLimit != null) 'rrspDeductionLimit': rrspDeductionLimit,
        if (rrspContributed != null) 'rrspContributed': rrspContributed,
        if (kidsUnder6 != null) 'kidsUnder6': kidsUnder6,
        if (kids6to17 != null) 'kids6to17': kids6to17,
        if (familyNetIncome != null) 'familyNetIncome': familyNetIncome,
        if (gicAmount != null) 'gicAmount': gicAmount,
        if (gicMaturityDate != null)
          'gicMaturityDate': gicMaturityDate!.toIso8601String(),
      };

  factory MoneyProfile.fromJson(Map<String, dynamic> json) {
    double? asDouble(Object? v) => v is num ? v.toDouble() : null;
    int? asInt(Object? v) => v is num ? v.toInt() : null;
    final by = json['birthYear'];
    final gicDate = json['gicMaturityDate'];
    return MoneyProfile(
      birthYear: by is num ? by.toInt() : null,
      tfsaContributed: asDouble(json['tfsaContributed']),
      province: Province.fromCode(json['province'] as String?),
      annualIncome: asDouble(json['annualIncome']),
      rrspDeductionLimit: asDouble(json['rrspDeductionLimit']),
      rrspContributed: asDouble(json['rrspContributed']),
      kidsUnder6: asInt(json['kidsUnder6']),
      kids6to17: asInt(json['kids6to17']),
      familyNetIncome: asDouble(json['familyNetIncome']),
      gicAmount: asDouble(json['gicAmount']),
      gicMaturityDate: gicDate is String ? DateTime.tryParse(gicDate) : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MoneyProfile &&
      other.birthYear == birthYear &&
      other.tfsaContributed == tfsaContributed &&
      other.province == province &&
      other.annualIncome == annualIncome &&
      other.rrspDeductionLimit == rrspDeductionLimit &&
      other.rrspContributed == rrspContributed &&
      other.kidsUnder6 == kidsUnder6 &&
      other.kids6to17 == kids6to17 &&
      other.familyNetIncome == familyNetIncome &&
      other.gicAmount == gicAmount &&
      other.gicMaturityDate == gicMaturityDate;

  @override
  int get hashCode => Object.hashAll([
        birthYear,
        tfsaContributed,
        province,
        annualIncome,
        rrspDeductionLimit,
        rrspContributed,
        kidsUnder6,
        kids6to17,
        familyNetIncome,
        gicAmount,
        gicMaturityDate,
      ]);
}
