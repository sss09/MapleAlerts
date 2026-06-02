/// Canadian Data Engine — deterministic, on-device rules + math for Canadian
/// money questions. Pure Dart (no Flutter), versioned, and intended to be
/// lifted wholesale into sibling apps.
///
/// App code imports ONLY this barrel; never reach into the files directly.
library;

export 'data/data_pack.dart';
export 'data/tfsa_limits.dart';
export 'domain/figure_source.dart';
export 'domain/money_profile.dart';
export 'domain/tfsa_room.dart';
export 'rules/tfsa_rule.dart';
export 'util/money_format.dart';
