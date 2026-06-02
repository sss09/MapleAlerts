/// Canadian provinces and territories. Used to select provincial tax brackets
/// and (later) province-specific benefits. Serialized by its two-letter [code].
enum Province {
  ab('AB', 'Alberta'),
  bc('BC', 'British Columbia'),
  mb('MB', 'Manitoba'),
  nb('NB', 'New Brunswick'),
  nl('NL', 'Newfoundland and Labrador'),
  ns('NS', 'Nova Scotia'),
  nt('NT', 'Northwest Territories'),
  nu('NU', 'Nunavut'),
  on('ON', 'Ontario'),
  pe('PE', 'Prince Edward Island'),
  qc('QC', 'Quebec'),
  sk('SK', 'Saskatchewan'),
  yt('YT', 'Yukon');

  const Province(this.code, this.displayName);

  /// Two-letter postal/standard code, e.g. 'ON'.
  final String code;

  /// Full human-readable name.
  final String displayName;

  /// Resolves a [Province] from its [code] (case-insensitive), or null.
  static Province? fromCode(String? code) {
    if (code == null) return null;
    final upper = code.toUpperCase();
    for (final p in Province.values) {
      if (p.code == upper) return p;
    }
    return null;
  }
}
