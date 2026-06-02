/// Canadian Data Engine — deterministic, on-device rules + math for Canadian
/// money questions. Pure Dart (no Flutter), versioned, and intended to be
/// lifted wholesale into sibling apps.
///
/// App code imports ONLY this barrel; never reach into the files directly.
library;

export 'data/ccb_amounts.dart';
export 'data/data_pack.dart';
export 'data/rrsp_limits.dart';
export 'data/tax_brackets.dart';
export 'data/tfsa_limits.dart';
export 'domain/ccb_benefit.dart';
export 'domain/figure_source.dart';
export 'domain/money_profile.dart';
export 'domain/province.dart';
export 'domain/rrsp_room.dart';
export 'domain/tfsa_room.dart';
export 'rules/ccb_rule.dart';
export 'rules/rrsp_rule.dart';
export 'rules/tax_rule.dart';
export 'rules/tfsa_rule.dart';
export 'util/money_format.dart';
