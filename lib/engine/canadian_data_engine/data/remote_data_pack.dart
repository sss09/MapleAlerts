import '../domain/province.dart';
import 'ccb_amounts.dart';
import 'data_pack.dart';
import 'oas_amounts.dart';
import 'tax_brackets.dart';

/// The pack JSON schema this build understands. A pack with any other value
/// is rejected wholesale (the embedded pack is used instead).
const int kSupportedPackSchemaVersion = 1;

/// A [DataPack] parsed from the hosted JSON pack. Pure Dart — parsing only,
/// no network, no Flutter.
///
/// Per-field fallback: any section that is missing or malformed delegates to
/// [_fallback] (the embedded pack), so a partial or partially-corrupt pack can
/// never break a rule. Construction throws [FormatException] only for the two
/// wholesale-reject cases: unsupported [kSupportedPackSchemaVersion] or a
/// missing `packVersion`.
class RemoteDataPack implements DataPack {
  RemoteDataPack._({
    required DataPack fallback,
    required this.packVersion,
    Map<int, int>? tfsaLimits,
    Map<int, int>? rrspMax,
    double? rrspBuffer,
    double? fhsaAnnual,
    double? fhsaLifetime,
    CcbParams? ccb,
    OasParams? oas,
    List<TaxBracket>? federal,
    Map<Province, List<TaxBracket>>? provincial,
  })  : _fallback = fallback,
        _tfsaLimits = tfsaLimits,
        _rrspMax = rrspMax,
        _rrspBuffer = rrspBuffer,
        _fhsaAnnual = fhsaAnnual,
        _fhsaLifetime = fhsaLifetime,
        _ccb = ccb,
        _oas = oas,
        _federal = federal,
        _provincial = provincial;

  factory RemoteDataPack.fromJson(
    Map<String, dynamic> json, {
    required DataPack fallback,
  }) {
    if (json['schemaVersion'] != kSupportedPackSchemaVersion) {
      throw FormatException(
          'Unsupported pack schemaVersion: ${json['schemaVersion']}');
    }
    final version = json['packVersion'];
    if (version is! String || version.isEmpty) {
      throw const FormatException('Pack is missing packVersion');
    }
    final tax = json['tax'];
    return RemoteDataPack._(
      fallback: fallback,
      packVersion: version,
      tfsaLimits: _intIntMap(json['tfsaAnnualLimits']),
      rrspMax: _intIntMap(json['rrspAnnualMax']),
      rrspBuffer: _asDouble(json['rrspOverContributionBuffer']),
      fhsaAnnual: _asDouble(
          json['fhsa'] is Map ? (json['fhsa'] as Map)['annualLimit'] : null),
      fhsaLifetime: _asDouble(
          json['fhsa'] is Map ? (json['fhsa'] as Map)['lifetimeLimit'] : null),
      ccb: _ccbParams(json['ccb']),
      oas: _oasParams(json['oas']),
      federal: _brackets(tax is Map ? tax['federal'] : null),
      provincial: _provincialBrackets(tax is Map ? tax['provincial'] : null),
    );
  }

  final DataPack _fallback;
  @override
  final String packVersion;
  final Map<int, int>? _tfsaLimits;
  final Map<int, int>? _rrspMax;
  final double? _rrspBuffer;
  final double? _fhsaAnnual;
  final double? _fhsaLifetime;
  final CcbParams? _ccb;
  final OasParams? _oas;
  final List<TaxBracket>? _federal;
  final Map<Province, List<TaxBracket>>? _provincial;

  // ── Defensive section parsers: any malformed shape → null (fallback) ──────

  static Map<int, int>? _intIntMap(dynamic raw) {
    if (raw is! Map || raw.isEmpty) return null;
    try {
      return raw.map((k, v) => MapEntry(int.parse(k as String), (v as num).toInt()));
    } catch (_) {
      return null;
    }
  }

  static double? _asDouble(dynamic raw) => raw is num ? raw.toDouble() : null;

  static CcbParams? _ccbParams(dynamic raw) {
    if (raw is! Map) return null;
    try {
      List<double> rates(dynamic v) =>
          (v as List).map((e) => (e as num).toDouble()).toList();
      final s1 = rates(raw['step1Rates']);
      final s2 = rates(raw['step2Rates']);
      if (s1.length != 4 || s2.length != 4) return null;
      return CcbParams(
        maxUnder6: (raw['maxUnder6'] as num).toDouble(),
        max6to17: (raw['max6to17'] as num).toDouble(),
        threshold1: (raw['threshold1'] as num).toDouble(),
        threshold2: (raw['threshold2'] as num).toDouble(),
        step1Rates: s1,
        step2Rates: s2,
      );
    } catch (_) {
      return null;
    }
  }

  static OasParams? _oasParams(dynamic raw) {
    if (raw is! Map) return null;
    try {
      return OasParams(
        recoveryThreshold: (raw['recoveryThreshold'] as num).toDouble(),
        recoveryRate: (raw['recoveryRate'] as num).toDouble(),
        upperThreshold65to74: (raw['upperThreshold65to74'] as num).toDouble(),
        upperThreshold75plus: (raw['upperThreshold75plus'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  static List<TaxBracket>? _brackets(dynamic raw) {
    if (raw is! List || raw.isEmpty) return null;
    try {
      return raw
          .map((b) => TaxBracket(
              ((b as List)[0] as num).toDouble(), (b[1] as num).toDouble()))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Map<Province, List<TaxBracket>>? _provincialBrackets(dynamic raw) {
    if (raw is! Map || raw.isEmpty) return null;
    try {
      final out = <Province, List<TaxBracket>>{};
      for (final entry in raw.entries) {
        final province = Province.values
            .where((p) => p.name == entry.key)
            .firstOrNull;
        if (province == null) return null;
        final brackets = _brackets(entry.value);
        if (brackets == null) return null;
        out[province] = brackets;
      }
      return out;
    } catch (_) {
      return null;
    }
  }

  // ── DataPack members: remote value, else fallback ─────────────────────────

  @override
  int? tfsaAnnualLimit(int year) =>
      _tfsaLimits?[year] ?? _fallback.tfsaAnnualLimit(year);

  @override
  int get tfsaFirstYear => _tfsaLimits == null
      ? _fallback.tfsaFirstYear
      : _tfsaLimits.keys.reduce((a, b) => a < b ? a : b);

  @override
  int get tfsaLatestYear => _tfsaLimits == null
      ? _fallback.tfsaLatestYear
      : _tfsaLimits.keys.reduce((a, b) => a > b ? a : b);

  @override
  List<TaxBracket> federalBrackets(int year) =>
      _federal ?? _fallback.federalBrackets(year);

  @override
  List<TaxBracket> provincialBrackets(int year, Province province) =>
      _provincial?[province] ?? _fallback.provincialBrackets(year, province);

  @override
  int? rrspAnnualMax(int year) =>
      _rrspMax?[year] ?? _fallback.rrspAnnualMax(year);

  @override
  double get rrspOverContributionBuffer =>
      _rrspBuffer ?? _fallback.rrspOverContributionBuffer;

  @override
  CcbParams ccbParams(int year) => _ccb ?? _fallback.ccbParams(year);

  @override
  OasParams oasParams(int year) => _oas ?? _fallback.oasParams(year);

  @override
  double get fhsaAnnualLimit => _fhsaAnnual ?? _fallback.fhsaAnnualLimit;

  @override
  double get fhsaLifetimeLimit => _fhsaLifetime ?? _fallback.fhsaLifetimeLimit;
}
