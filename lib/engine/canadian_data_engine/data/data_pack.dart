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
}
