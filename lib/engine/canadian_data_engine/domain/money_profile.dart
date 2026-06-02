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

  const MoneyProfile({
    this.birthYear,
    this.tfsaContributed,
    this.province,
    this.annualIncome,
    this.rrspDeductionLimit,
    this.rrspContributed,
  });

  static const empty = MoneyProfile();

  MoneyProfile copyWith({
    int? birthYear,
    double? tfsaContributed,
    Province? province,
    double? annualIncome,
    double? rrspDeductionLimit,
    double? rrspContributed,
    bool clearBirthYear = false,
    bool clearTfsaContributed = false,
    bool clearProvince = false,
    bool clearAnnualIncome = false,
    bool clearRrspDeductionLimit = false,
    bool clearRrspContributed = false,
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
    );
  }

  Map<String, dynamic> toJson() => {
        if (birthYear != null) 'birthYear': birthYear,
        if (tfsaContributed != null) 'tfsaContributed': tfsaContributed,
        if (province != null) 'province': province!.code,
        if (annualIncome != null) 'annualIncome': annualIncome,
        if (rrspDeductionLimit != null) 'rrspDeductionLimit': rrspDeductionLimit,
        if (rrspContributed != null) 'rrspContributed': rrspContributed,
      };

  factory MoneyProfile.fromJson(Map<String, dynamic> json) {
    double? asDouble(Object? v) => v is num ? v.toDouble() : null;
    final by = json['birthYear'];
    return MoneyProfile(
      birthYear: by is num ? by.toInt() : null,
      tfsaContributed: asDouble(json['tfsaContributed']),
      province: Province.fromCode(json['province'] as String?),
      annualIncome: asDouble(json['annualIncome']),
      rrspDeductionLimit: asDouble(json['rrspDeductionLimit']),
      rrspContributed: asDouble(json['rrspContributed']),
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
      other.rrspContributed == rrspContributed;

  @override
  int get hashCode => Object.hash(birthYear, tfsaContributed, province,
      annualIncome, rrspDeductionLimit, rrspContributed);
}
