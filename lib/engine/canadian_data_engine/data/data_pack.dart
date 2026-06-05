import '../domain/province.dart';
import 'ccb_amounts.dart';
import 'fhsa_limits.dart';
import 'oas_amounts.dart';
import 'rates_data.dart';
import 'rrsp_limits.dart';
import 'tax_brackets.dart';
import 'tfsa_limits.dart';

/// Overall embedded-pack vintage (ISO date) — directly comparable against a
/// hosted pack's `packVersion` (ISO dates sort lexicographically). Bump
/// whenever any embedded table changes.
const String kEmbeddedPackVersion = '2026-06-02';

/// Read-only source of the changing Canadian numbers the rules depend on
/// (contribution limits, benefit amounts, rate snapshots…).
///
/// This is the override seam: today only [EmbeddedDataPack] (const tables baked
/// into the app) implements it. A future `HostedDataPack` can fetch + cache a
/// JSON file and override values with no changes to any rule.
abstract class DataPack {
  /// Identifies which vintage of data this pack carries.
  String get packVersion;

  /// The TFSA annual contribution limit for [year], or null if unknown.
  int? tfsaAnnualLimit(int year);

  /// The earliest year the pack has a TFSA limit for (TFSA began in 2009).
  int get tfsaFirstYear;

  /// The latest year the pack has a TFSA limit for.
  int get tfsaLatestYear;

  /// Federal marginal tax brackets for [year].
  List<TaxBracket> federalBrackets(int year);

  /// Provincial/territorial marginal tax brackets for [year] and [province].
  List<TaxBracket> provincialBrackets(int year, Province province);

  /// The RRSP dollar maximum for [year], or null if unknown.
  int? rrspAnnualMax(int year);

  /// CRA lifetime RRSP over-contribution buffer (dollars).
  double get rrspOverContributionBuffer;

  /// Canada Child Benefit parameters for the benefit year covering [year].
  CcbParams ccbParams(int year);

  /// OAS recovery-tax (clawback) parameters for [year].
  OasParams oasParams(int year);

  /// FHSA annual participation limit (dollars).
  double get fhsaAnnualLimit;

  /// FHSA lifetime contribution limit (dollars).
  double get fhsaLifetimeLimit;

  /// Institution rate snapshot (HISA + 1-yr GIC). Returns [RatesData.empty]
  /// when the pack carries no rates section.
  RatesData get rates;
}

/// The default pack: numbers compiled into the app from [kTfsaAnnualLimits].
class EmbeddedDataPack implements DataPack {
  const EmbeddedDataPack();

  @override
  String get packVersion => kEmbeddedPackVersion;

  @override
  int? tfsaAnnualLimit(int year) => kTfsaAnnualLimits[year];

  @override
  int get tfsaFirstYear =>
      kTfsaAnnualLimits.keys.reduce((a, b) => a < b ? a : b);

  @override
  int get tfsaLatestYear =>
      kTfsaAnnualLimits.keys.reduce((a, b) => a > b ? a : b);

  @override
  List<TaxBracket> federalBrackets(int year) => kFederalBrackets2025;

  @override
  List<TaxBracket> provincialBrackets(int year, Province province) =>
      kProvincialBrackets2025[province] ?? const [];

  @override
  int? rrspAnnualMax(int year) => kRrspAnnualMax[year];

  @override
  double get rrspOverContributionBuffer => kRrspOverContributionBuffer;

  @override
  CcbParams ccbParams(int year) => kCcbParams2025;

  @override
  OasParams oasParams(int year) => kOasParams2025;

  @override
  double get fhsaAnnualLimit => kFhsaAnnualLimit;

  @override
  double get fhsaLifetimeLimit => kFhsaLifetimeLimit;

  /// The embedded pack carries no institution rates — callers receive the empty
  /// sentinel and must handle the missing-data case gracefully.
  @override
  RatesData get rates => RatesData.empty;
}
