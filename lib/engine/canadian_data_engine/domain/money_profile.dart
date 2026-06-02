/// The user's financial inputs that the engine's rules read from.
///
/// Deliberately small for the first slice (TFSA only). New inputs — province,
/// account balances, income, number of children, life-stage — are added as
/// fields here, NOT as new prefs keys scattered across the app. Pure Dart;
/// JSON (de)serialization lives here so there is one place that knows the shape.
class MoneyProfile {
  /// Four-digit year of birth, used to derive TFSA eligibility (age 18).
  final int? birthYear;

  /// Total amount the user has ever contributed to their TFSA, in dollars.
  final double? tfsaContributed;

  const MoneyProfile({this.birthYear, this.tfsaContributed});

  static const empty = MoneyProfile();

  MoneyProfile copyWith({
    int? birthYear,
    double? tfsaContributed,
    bool clearBirthYear = false,
    bool clearTfsaContributed = false,
  }) {
    return MoneyProfile(
      birthYear: clearBirthYear ? null : (birthYear ?? this.birthYear),
      tfsaContributed:
          clearTfsaContributed ? null : (tfsaContributed ?? this.tfsaContributed),
    );
  }

  Map<String, dynamic> toJson() => {
        if (birthYear != null) 'birthYear': birthYear,
        if (tfsaContributed != null) 'tfsaContributed': tfsaContributed,
      };

  factory MoneyProfile.fromJson(Map<String, dynamic> json) {
    final by = json['birthYear'];
    final tc = json['tfsaContributed'];
    return MoneyProfile(
      birthYear: by is num ? by.toInt() : null,
      tfsaContributed: tc is num ? tc.toDouble() : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MoneyProfile &&
      other.birthYear == birthYear &&
      other.tfsaContributed == tfsaContributed;

  @override
  int get hashCode => Object.hash(birthYear, tfsaContributed);
}
