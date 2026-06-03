/// Reads the current value for a watched-source [id] from a decoded pack.
/// Year-keyed tables use the latest entry as the comparison baseline.
num? currentValueFor(Map<String, dynamic> pack, String id, int year) {
  switch (id) {
    case 'tfsa':
      final m = (pack['tfsaAnnualLimits'] as Map).cast<String, dynamic>();
      return _latest(m);
    case 'rrsp':
      final m = (pack['rrspAnnualMax'] as Map).cast<String, dynamic>();
      return _latest(m);
    case 'oas':
      return (pack['oas'] as Map)['recoveryThreshold'] as num?;
    case 'ccb_maxUnder6':
      return (pack['ccb'] as Map)['maxUnder6'] as num?;
    case 'ccb_max6to17':
      return (pack['ccb'] as Map)['max6to17'] as num?;
    case 'ccb_threshold1':
      return (pack['ccb'] as Map)['threshold1'] as num?;
    case 'ccb_threshold2':
      return (pack['ccb'] as Map)['threshold2'] as num?;
    default:
      return null;
  }
}

num? _latest(Map<String, dynamic> yearMap) {
  if (yearMap.isEmpty) return null;
  final latestYear =
      yearMap.keys.map(int.parse).reduce((a, b) => a > b ? a : b);
  return yearMap['$latestYear'] as num?;
}

/// Returns a NEW pack map with [changes] applied (id → new value) for [year],
/// and packVersion set to [newVersion]. Pure: input map is not mutated.
Map<String, dynamic> applyChange(
  Map<String, dynamic> pack,
  Map<String, num> changes, {
  required int year,
  required String newVersion,
}) {
  final out = Map<String, dynamic>.from(pack);
  // deep-copy the mutable sub-maps we touch
  out['tfsaAnnualLimits'] =
      Map<String, dynamic>.from(pack['tfsaAnnualLimits'] as Map);
  out['rrspAnnualMax'] =
      Map<String, dynamic>.from(pack['rrspAnnualMax'] as Map);
  out['oas'] = Map<String, dynamic>.from(pack['oas'] as Map);
  out['ccb'] = Map<String, dynamic>.from(pack['ccb'] as Map);

  changes.forEach((id, value) {
    switch (id) {
      case 'tfsa':
        (out['tfsaAnnualLimits'] as Map)['$year'] = value;
      case 'rrsp':
        (out['rrspAnnualMax'] as Map)['$year'] = value;
      case 'oas':
        (out['oas'] as Map)['recoveryThreshold'] = value;
      case 'ccb_maxUnder6':
        (out['ccb'] as Map)['maxUnder6'] = value;
      case 'ccb_max6to17':
        (out['ccb'] as Map)['max6to17'] = value;
      case 'ccb_threshold1':
        (out['ccb'] as Map)['threshold1'] = value;
      case 'ccb_threshold2':
        (out['ccb'] as Map)['threshold2'] = value;
    }
  });
  out['packVersion'] = newVersion;
  return out;
}
