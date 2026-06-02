import '../domain/province.dart';
import 'rrsp_limits.dart';
import 'tax_brackets.dart';
import 'tfsa_limits.dart';

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
}

/// The default pack: numbers compiled into the app from [kTfsaAnnualLimits].
class EmbeddedDataPack implements DataPack {
  const EmbeddedDataPack();

  @override
  String get packVersion => kTfsaDataPackVersion;

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
}
