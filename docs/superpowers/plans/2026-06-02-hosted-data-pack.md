# Hosted Data Pack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Canada's rule figures update over the air from one hosted JSON file (GitHub Pages) — no app-store release.

**Architecture:** `RemoteDataPack.fromJson` (pure-Dart, per-field fallback to `EmbeddedDataPack`) implements the existing `DataPack` seam; `DataPackService` (BocRateService pattern: injectable fetcher + prefs cache + 24h TTL) fetches `https://sss09.github.io/MapleAlerts/datapack/pack.json`; `dataPackProvider` resolves newest-of(remote, embedded) and replaces the 6 `const EmbeddedDataPack()` call sites. The pack file itself is generated from the embedded tables by `tool/generate_data_pack.dart` and deployed by the existing `pages.yml` (Flutter copies `web/` verbatim).

**Tech Stack:** Flutter/Dart, Riverpod 2.x, `http` (already a dep), shared_preferences. Spec: `docs/superpowers/specs/2026-06-02-hosted-data-pack-design.md`.

**Conventions:** PowerShell — chain with `;` not `&&`. Strict TDD per task. Tests never touch network or real time. Commit after each task. All work on `main`.

---

### Task 1: Engine — `RemoteDataPack` + `kEmbeddedPackVersion` (TDD)

**Files:**
- Create: `lib/engine/canadian_data_engine/data/remote_data_pack.dart`
- Modify: `lib/engine/canadian_data_engine/data/data_pack.dart` (packVersion)
- Modify: `lib/engine/canadian_data_engine/canadian_data_engine.dart` (export the new file; check the barrel's existing export style first)
- Test: `test/engine/canadian_data_engine/remote_data_pack_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

void main() {
  const fallback = EmbeddedDataPack();

  Map<String, dynamic> fullJson() => {
        'schemaVersion': 1,
        'packVersion': '2027-01-01',
        'tfsaAnnualLimits': {'2009': 5000, '2026': 7000, '2027': 7500},
        'rrspAnnualMax': {'2027': 34000},
        'rrspOverContributionBuffer': 2000,
        'fhsa': {'annualLimit': 8000, 'lifetimeLimit': 40000},
        'ccb': {
          'maxUnder6': 8100.0,
          'max6to17': 6800.0,
          'threshold1': 38000.0,
          'threshold2': 82000.0,
          'step1Rates': [0.07, 0.135, 0.19, 0.23],
          'step2Rates': [0.032, 0.057, 0.08, 0.095],
        },
        'oas': {
          'recoveryThreshold': 95000.0,
          'recoveryRate': 0.15,
          'upperThreshold65to74': 153000.0,
          'upperThreshold75plus': 159000.0,
        },
        'tax': {
          'federal': [
            [0, 0.14],
            [60000, 0.205],
          ],
          'provincial': {
            'on': [
              [0, 0.0505],
              [55000, 0.0915],
            ],
          },
        },
      };

  group('RemoteDataPack.fromJson', () {
    test('full pack overrides every member', () {
      final pack = RemoteDataPack.fromJson(fullJson(), fallback: fallback);
      expect(pack.packVersion, '2027-01-01');
      expect(pack.tfsaAnnualLimit(2027), 7500);
      expect(pack.tfsaLatestYear, 2027);
      expect(pack.tfsaFirstYear, 2009);
      expect(pack.rrspAnnualMax(2027), 34000);
      expect(pack.rrspOverContributionBuffer, 2000);
      expect(pack.fhsaAnnualLimit, 8000);
      expect(pack.fhsaLifetimeLimit, 40000);
      expect(pack.ccbParams(2027).maxUnder6, 8100);
      expect(pack.oasParams(2027).recoveryThreshold, 95000);
      expect(pack.federalBrackets(2027).first.rate, 0.14);
      expect(pack.federalBrackets(2027)[1].lowerBound, 60000);
      expect(pack.provincialBrackets(2027, Province.on)[1].lowerBound, 55000);
    });

    test('empty pack delegates everything to the fallback', () {
      final pack = RemoteDataPack.fromJson(
        {'schemaVersion': 1, 'packVersion': '2027-01-01'},
        fallback: fallback,
      );
      expect(pack.tfsaAnnualLimit(2026), fallback.tfsaAnnualLimit(2026));
      expect(pack.tfsaFirstYear, fallback.tfsaFirstYear);
      expect(pack.rrspAnnualMax(2026), fallback.rrspAnnualMax(2026));
      expect(pack.ccbParams(2026).maxUnder6, fallback.ccbParams(2026).maxUnder6);
      expect(pack.oasParams(2026).recoveryThreshold,
          fallback.oasParams(2026).recoveryThreshold);
      expect(pack.fhsaLifetimeLimit, fallback.fhsaLifetimeLimit);
      expect(pack.federalBrackets(2026).length,
          fallback.federalBrackets(2026).length);
      expect(pack.provincialBrackets(2026, Province.bc).length,
          fallback.provincialBrackets(2026, Province.bc).length);
    });

    test('a year missing from a present table delegates to the fallback', () {
      final json = {
        'schemaVersion': 1,
        'packVersion': '2027-01-01',
        'tfsaAnnualLimits': {'2027': 7500},
      };
      final pack = RemoteDataPack.fromJson(json, fallback: fallback);
      expect(pack.tfsaAnnualLimit(2027), 7500);
      expect(pack.tfsaAnnualLimit(2020), fallback.tfsaAnnualLimit(2020));
    });

    test('one corrupt section falls back alone, others still apply', () {
      final json = fullJson();
      json['ccb'] = {'maxUnder6': 'not-a-number'};
      final pack = RemoteDataPack.fromJson(json, fallback: fallback);
      expect(pack.ccbParams(2026).maxUnder6, fallback.ccbParams(2026).maxUnder6);
      expect(pack.tfsaAnnualLimit(2027), 7500); // unaffected
    });

    test('unsupported schemaVersion throws', () {
      expect(
        () => RemoteDataPack.fromJson(
            {'schemaVersion': 2, 'packVersion': 'x'}, fallback: fallback),
        throwsFormatException,
      );
    });

    test('missing packVersion throws', () {
      expect(
        () => RemoteDataPack.fromJson({'schemaVersion': 1}, fallback: fallback),
        throwsFormatException,
      );
    });
  });

  test('EmbeddedDataPack.packVersion is the comparable ISO-date constant', () {
    expect(fallback.packVersion, kEmbeddedPackVersion);
    expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(kEmbeddedPackVersion), isTrue);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/engine/canadian_data_engine/remote_data_pack_test.dart`
Expected: FAIL — `RemoteDataPack`/`kEmbeddedPackVersion` undefined.

- [ ] **Step 3: Implement**

In `lib/engine/canadian_data_engine/data/data_pack.dart`, add above `DataPack`:

```dart
/// Overall embedded-pack vintage (ISO date) — directly comparable against a
/// hosted pack's `packVersion` (ISO dates sort lexicographically). Bump
/// whenever any embedded table changes.
const String kEmbeddedPackVersion = '2026-06-02';
```

and change `EmbeddedDataPack.packVersion`:

```dart
  @override
  String get packVersion => kEmbeddedPackVersion;
```

(The per-table vintage strings like `kTfsaDataPackVersion` stay on their tables as documentation.)

Create `lib/engine/canadian_data_engine/data/remote_data_pack.dart`:

```dart
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
```

Add `export 'data/remote_data_pack.dart';` to `lib/engine/canadian_data_engine/canadian_data_engine.dart` (match the barrel's existing style; also confirm `data_pack.dart`, `Province`, and the data tables are already exported — they are used by existing tests via the barrel).

NOTE: a TFSA-year-table subtlety — when the remote pack carries `tfsaAnnualLimits`, the `tfsaFirstYear..tfsaLatestYear` range comes from the REMOTE table, but `tfsaAnnualLimit(year)` falls back per-year. A remote table holding only `{'2027': 7500}` would make `tfsaFirstYear` 2027. The shipped pack always carries the FULL table (generated from embedded), so this cannot occur in practice; the per-year fallback test pins the lookup behaviour.

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/engine/canadian_data_engine/remote_data_pack_test.dart`
Expected: PASS, 7 tests.

- [ ] **Step 5: Run the whole engine suite (packVersion change is engine-wide)**

Run: `flutter test test/engine`
Expected: ALL pass (existing tests assert packVersion is non-empty, not its value).

- [ ] **Step 6: Commit**

```bash
git add lib/engine/canadian_data_engine test/engine/canadian_data_engine/remote_data_pack_test.dart
git commit -m "feat(engine): RemoteDataPack - hosted pack parsing with per-field fallback"
```

---

### Task 2: The pack file — generator + sanity test

**Files:**
- Create: `tool/generate_data_pack.dart`
- Create: `web/datapack/pack.json` (generated)
- Test: `test/engine/canadian_data_engine/pack_file_test.dart`

- [ ] **Step 1: Write the generator**

`tool/generate_data_pack.dart`:

```dart
// Regenerates web/datapack/pack.json from the embedded tables.
// Run after any embedded-table change:  dart run tool/generate_data_pack.dart
import 'dart:convert';
import 'dart:io';

import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

void main() {
  const pack = EmbeddedDataPack();
  const year = 2026; // representative year for the year-keyed param lookups
  final ccb = pack.ccbParams(year);
  final oas = pack.oasParams(year);

  List<List<num>> brackets(List<TaxBracket> bs) =>
      bs.map((b) => [b.lowerBound, b.rate]).toList();

  final json = <String, dynamic>{
    'schemaVersion': kSupportedPackSchemaVersion,
    'packVersion': kEmbeddedPackVersion,
    'tfsaAnnualLimits': {
      for (var y = pack.tfsaFirstYear; y <= pack.tfsaLatestYear; y++)
        '$y': pack.tfsaAnnualLimit(y),
    },
    'rrspAnnualMax': {
      for (final e in kRrspAnnualMax.entries) '${e.key}': e.value,
    },
    'rrspOverContributionBuffer': pack.rrspOverContributionBuffer,
    'fhsa': {
      'annualLimit': pack.fhsaAnnualLimit,
      'lifetimeLimit': pack.fhsaLifetimeLimit,
    },
    'ccb': {
      'maxUnder6': ccb.maxUnder6,
      'max6to17': ccb.max6to17,
      'threshold1': ccb.threshold1,
      'threshold2': ccb.threshold2,
      'step1Rates': ccb.step1Rates,
      'step2Rates': ccb.step2Rates,
    },
    'oas': {
      'recoveryThreshold': oas.recoveryThreshold,
      'recoveryRate': oas.recoveryRate,
      'upperThreshold65to74': oas.upperThreshold65to74,
      'upperThreshold75plus': oas.upperThreshold75plus,
    },
    'tax': {
      'federal': brackets(pack.federalBrackets(year)),
      'provincial': {
        for (final p in Province.values)
          if (pack.provincialBrackets(year, p).isNotEmpty)
            p.name: brackets(pack.provincialBrackets(year, p)),
      },
    },
  };

  final file = File('web/datapack/pack.json');
  file.createSync(recursive: true);
  file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n');
  stdout.writeln('Wrote ${file.path} (packVersion $kEmbeddedPackVersion)');
}
```

If `kRrspAnnualMax`, `kSupportedPackSchemaVersion`, or `kEmbeddedPackVersion` are not exported by the barrel, import the data files directly (`package:maple_alerts/engine/canadian_data_engine/data/rrsp_limits.dart` etc.).

- [ ] **Step 2: Generate the pack**

Run: `dart run tool/generate_data_pack.dart`
Expected: `Wrote web/datapack/pack.json (packVersion 2026-06-02)`. Inspect the file — it must contain all 13 provinces under `tax.provincial`.

- [ ] **Step 3: Write the sanity test (keeps the deployed file honest)**

`test/engine/canadian_data_engine/pack_file_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';

void main() {
  test('shipped web/datapack/pack.json parses and matches the embedded pack',
      () {
    const embedded = EmbeddedDataPack();
    final raw = File('web/datapack/pack.json').readAsStringSync();
    final pack = RemoteDataPack.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
      fallback: embedded,
    );

    expect(pack.packVersion, kEmbeddedPackVersion);
    expect(pack.tfsaAnnualLimit(2026), embedded.tfsaAnnualLimit(2026));
    expect(pack.tfsaFirstYear, embedded.tfsaFirstYear);
    expect(pack.rrspAnnualMax(2026), embedded.rrspAnnualMax(2026));
    expect(pack.rrspOverContributionBuffer,
        embedded.rrspOverContributionBuffer);
    expect(pack.fhsaLifetimeLimit, embedded.fhsaLifetimeLimit);
    expect(pack.ccbParams(2026).maxUnder6, embedded.ccbParams(2026).maxUnder6);
    expect(pack.ccbParams(2026).step2Rates,
        embedded.ccbParams(2026).step2Rates);
    expect(pack.oasParams(2026).recoveryThreshold,
        embedded.oasParams(2026).recoveryThreshold);
    expect(pack.federalBrackets(2026).length,
        embedded.federalBrackets(2026).length);
    for (final p in Province.values) {
      expect(pack.provincialBrackets(2026, p).length,
          embedded.provincialBrackets(2026, p).length,
          reason: 'province ${p.code} bracket count drifted');
    }
  });
}
```

- [ ] **Step 4: Run it**

Run: `flutter test test/engine/canadian_data_engine/pack_file_test.dart`
Expected: PASS. (If it fails, the generator and parser disagree — fix the generator, never the test.)

- [ ] **Step 5: Commit**

```bash
git add tool/generate_data_pack.dart web/datapack/pack.json test/engine/canadian_data_engine/pack_file_test.dart
git commit -m "feat: data pack file + generator + shipped-file sanity test"
```

---

### Task 3: `DataPackService` — fetch + cache + TTL (TDD)

**Files:**
- Modify: `lib/utils/constants.dart` (4 constants)
- Create: `lib/services/data_pack_service.dart`
- Test: `test/services/data_pack_service_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/services/data_pack_service.dart';
import 'package:maple_alerts/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _validPack =
    '{"schemaVersion":1,"packVersion":"2099-01-01"}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 6, 2, 12);

  test('refreshIfStale fetches, validates and caches when no cache exists',
      () async {
    SharedPreferences.setMockInitialValues({});
    var fetches = 0;
    final svc = DataPackService(
      fetch: (_) async {
        fetches++;
        return _validPack;
      },
      now: () => now,
    );

    final fresh = await svc.refreshIfStale();
    expect(fresh, _validPack);
    expect(fetches, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kDataPackJsonKey), _validPack);
    expect(prefs.getString(kDataPackFetchedAtKey), now.toIso8601String());
  });

  test('refreshIfStale is a no-op when the cache is fresh', () async {
    SharedPreferences.setMockInitialValues({
      kDataPackJsonKey: _validPack,
      kDataPackFetchedAtKey:
          now.subtract(const Duration(hours: 1)).toIso8601String(),
    });
    var fetches = 0;
    final svc = DataPackService(
      fetch: (_) async {
        fetches++;
        return _validPack;
      },
      now: () => now,
    );
    expect(await svc.refreshIfStale(), isNull);
    expect(fetches, 0);
  });

  test('refreshIfStale fetches again when the cache is older than 24h',
      () async {
    SharedPreferences.setMockInitialValues({
      kDataPackJsonKey: _validPack,
      kDataPackFetchedAtKey:
          now.subtract(const Duration(hours: 25)).toIso8601String(),
    });
    var fetches = 0;
    final svc = DataPackService(
      fetch: (_) async {
        fetches++;
        return _validPack;
      },
      now: () => now,
    );
    expect(await svc.refreshIfStale(), _validPack);
    expect(fetches, 1);
  });

  test('a failed fetch keeps the previous cache and returns null', () async {
    SharedPreferences.setMockInitialValues({
      kDataPackJsonKey: _validPack,
      kDataPackFetchedAtKey:
          now.subtract(const Duration(hours: 25)).toIso8601String(),
    });
    final svc = DataPackService(
      fetch: (_) async => throw Exception('offline'),
      now: () => now,
    );
    expect(await svc.refreshIfStale(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kDataPackJsonKey), _validPack);
  });

  test('a pack that fails validation is not cached', () async {
    SharedPreferences.setMockInitialValues({});
    final svc = DataPackService(
      fetch: (_) async => '{"schemaVersion":99,"packVersion":"x"}',
      now: () => now,
    );
    expect(await svc.refreshIfStale(), isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(kDataPackJsonKey), isNull);
  });

  test('loadCached returns the stored JSON or null', () async {
    SharedPreferences.setMockInitialValues({kDataPackJsonKey: _validPack});
    expect(await DataPackService(now: () => now).loadCached(), _validPack);
    SharedPreferences.setMockInitialValues({});
    expect(await DataPackService(now: () => now).loadCached(), isNull);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/services/data_pack_service_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement**

In `lib/utils/constants.dart` (next to the BoC constants):

```dart
/// Hosted data pack — the one JSON file that keeps Canadian figures current
/// without an app release (see docs/superpowers/specs/2026-06-02-hosted-data-pack-design.md).
const String kDataPackUrl =
    'https://sss09.github.io/MapleAlerts/datapack/pack.json';

/// Prefs key: raw cached pack JSON.
const String kDataPackJsonKey = 'data_pack_json_v1';

/// Prefs key: ISO timestamp of the last successful pack fetch.
const String kDataPackFetchedAtKey = 'data_pack_fetched_at_v1';

/// Re-fetch the pack when the cache is older than this.
const Duration kDataPackTtl = Duration(hours: 24);
```

Create `lib/services/data_pack_service.dart`:

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/canadian_data_engine/canadian_data_engine.dart';
import '../utils/constants.dart';

/// Signature for the HTTP fetch — injectable so tests never hit the network.
typedef PackFetcher = Future<String> Function(Uri url);

/// Fetches + caches the hosted data pack (same pattern as [BocRateService]):
/// injectable fetcher, prefs cache, 24h TTL, every failure path swallowed.
class DataPackService {
  DataPackService({PackFetcher? fetch, DateTime Function()? now})
      : _fetch = fetch ?? _defaultFetch,
        _now = now ?? DateTime.now;

  final PackFetcher _fetch;
  final DateTime Function() _now;

  static Future<String> _defaultFetch(Uri url) async {
    final res = await http.get(url).timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) {
      throw http.ClientException('HTTP ${res.statusCode}', url);
    }
    return res.body;
  }

  /// The cached raw pack JSON, or null.
  Future<String?> loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(kDataPackJsonKey);
    } catch (_) {
      return null;
    }
  }

  /// Fetches a fresh pack when the cache is older than [kDataPackTtl].
  /// Returns the fresh JSON on success, null when the cache is still fresh or
  /// anything fails (offline, bad status, pack fails validation) — in which
  /// case the previous cache is left untouched.
  Future<String?> refreshIfStale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fetchedAt =
          DateTime.tryParse(prefs.getString(kDataPackFetchedAtKey) ?? '');
      if (fetchedAt != null && _now().difference(fetchedAt) < kDataPackTtl) {
        return null; // cache is fresh
      }
      final body = await _fetch(Uri.parse(kDataPackUrl));
      // Validation gate: must parse as a supported pack before we cache it.
      RemoteDataPack.fromJson(
        jsonDecode(body) as Map<String, dynamic>,
        fallback: const EmbeddedDataPack(),
      );
      await prefs.setString(kDataPackJsonKey, body);
      await prefs.setString(
          kDataPackFetchedAtKey, _now().toIso8601String());
      return body;
    } catch (_) {
      return null; // fail-soft: keep whatever cache we had
    }
  }
}
```

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/services/data_pack_service_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/utils/constants.dart lib/services/data_pack_service.dart test/services/data_pack_service_test.dart
git commit -m "feat: DataPackService - fetch/cache the hosted pack (24h TTL, fail-soft)"
```

---

### Task 4: `dataPackProvider` + call-site swap (TDD)

**Files:**
- Create: `lib/providers/data_pack_provider.dart`
- Modify: `lib/providers/best_move_provider.dart:13`, `lib/providers/money_insights_provider.dart:15,33,50,76`, `lib/providers/tfsa_insight_provider.dart:16`
- Modify: `lib/main.dart` (startup hook)
- Test: `test/providers/data_pack_provider_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart';
import 'package:maple_alerts/providers/data_pack_provider.dart';

void main() {
  test('null cache resolves to the embedded pack', () {
    expect(resolveDataPack(null), isA<EmbeddedDataPack>());
  });

  test('garbage cache resolves to the embedded pack', () {
    expect(resolveDataPack('not json'), isA<EmbeddedDataPack>());
    expect(resolveDataPack('{"schemaVersion":99,"packVersion":"x"}'),
        isA<EmbeddedDataPack>());
  });

  test('an older or equal cached pack loses to embedded', () {
    expect(
        resolveDataPack(
            '{"schemaVersion":1,"packVersion":"2020-01-01"}'),
        isA<EmbeddedDataPack>());
    expect(
        resolveDataPack(
            '{"schemaVersion":1,"packVersion":"$kEmbeddedPackVersion"}'),
        isA<EmbeddedDataPack>());
  });

  test('a newer cached pack wins', () {
    final pack = resolveDataPack(
        '{"schemaVersion":1,"packVersion":"2099-01-01","tfsaAnnualLimits":{"2099":9000}}');
    expect(pack, isA<RemoteDataPack>());
    expect(pack.packVersion, '2099-01-01');
    expect(pack.tfsaAnnualLimit(2099), 9000);
    // Per-field fallback still reaches embedded data.
    expect(pack.tfsaAnnualLimit(2026), const EmbeddedDataPack().tfsaAnnualLimit(2026));
  });

  test('dataPackProvider follows cachedPackJsonProvider updates', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(dataPackProvider), isA<EmbeddedDataPack>());
    container.read(cachedPackJsonProvider.notifier).state =
        '{"schemaVersion":1,"packVersion":"2099-01-01"}';
    expect(container.read(dataPackProvider), isA<RemoteDataPack>());
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/providers/data_pack_provider_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement**

Create `lib/providers/data_pack_provider.dart`:

```dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../engine/canadian_data_engine/canadian_data_engine.dart';
import '../services/data_pack_service.dart';

/// Raw cached pack JSON. Seeded from prefs + refreshed over the air by
/// [initDataPack]; null until then (or when no cache exists).
final cachedPackJsonProvider = StateProvider<String?>((ref) => null);

/// Resolves which [DataPack] the app should use: the cached hosted pack when
/// it parses AND is strictly newer than the embedded one (so an app update
/// beats a stale cache), else the embedded pack.
DataPack resolveDataPack(String? cachedJson) {
  if (cachedJson == null) return const EmbeddedDataPack();
  try {
    final remote = RemoteDataPack.fromJson(
      jsonDecode(cachedJson) as Map<String, dynamic>,
      fallback: const EmbeddedDataPack(),
    );
    // ISO dates compare lexicographically.
    if (remote.packVersion.compareTo(kEmbeddedPackVersion) > 0) return remote;
  } catch (_) {
    // Unparseable cache — embedded wins.
  }
  return const EmbeddedDataPack();
}

/// The app-wide [DataPack] every rule provider reads.
final dataPackProvider = Provider<DataPack>(
    (ref) => resolveDataPack(ref.watch(cachedPackJsonProvider)));

/// Startup hook: seed the provider from the prefs cache, then refresh over
/// the air when stale. Fire-and-forget — never blocks or throws.
Future<void> initDataPack(ProviderContainer container,
    {DataPackService? service}) async {
  try {
    final svc = service ?? DataPackService();
    final cached = await svc.loadCached();
    if (cached != null) {
      container.read(cachedPackJsonProvider.notifier).state = cached;
    }
    final fresh = await svc.refreshIfStale();
    if (fresh != null) {
      container.read(cachedPackJsonProvider.notifier).state = fresh;
    }
  } catch (_) {
    // Fail-soft: embedded pack remains in effect.
  }
}
```

Swap the 6 call sites. In each of `best_move_provider.dart`, `money_insights_provider.dart` (4 sites), `tfsa_insight_provider.dart`: add `import 'data_pack_provider.dart';` and replace every `dataPack: const EmbeddedDataPack(),` with `dataPack: ref.watch(dataPackProvider),`. (All 6 sites are inside provider bodies where `ref` is in scope; remove the now-unused `EmbeddedDataPack` import only if the analyzer flags it.)

In `lib/main.dart`: change the runApp wiring so the same container serves the app and the startup hook:

```dart
final container = ProviderContainer();
unawaited(initDataPack(container));
runApp(UncontrolledProviderScope(
  container: container,
  child: const MapleAlertsApp(),
));
```

with imports `dart:async` (for `unawaited`), `package:maple_alerts/providers/data_pack_provider.dart`, and `UncontrolledProviderScope` from flutter_riverpod (replaces the current `ProviderScope(child: ...)`).

- [ ] **Step 4: Run to verify pass + regressions**

Run: `flutter test test/providers test/features/money test/engine`
Expected: ALL pass (existing money tests override providers / construct rules directly, so the swap is invisible to them; if any test fails on the new provider chain, override `dataPackProvider` with `const EmbeddedDataPack()` in that test's container).

- [ ] **Step 5: Commit**

```bash
git add lib/providers lib/main.dart test/providers/data_pack_provider_test.dart
git commit -m "feat: dataPackProvider - hosted pack resolution wired into all rule providers"
```

---

### Task 5: Trust line in the You tab (TDD)

**Files:**
- Modify: `lib/features/reminders/presentation/screens/profile_screen_v2.dart` (after the Privacy caption Padding, ~line 167)
- Test: `test/features/reminders/presentation/screens/profile_screen_v2_test.dart` (extend)

- [ ] **Step 1: Write the failing test** (same scaffolding as the existing Privacy test in that file)

```dart
testWidgets('Privacy section shows the Canadian-data pack version', (t) async {
  final spy = AnalyticsSpy();
  final container = ProviderContainer(overrides: [
    subscriptionProvider.overrideWith((ref) => _StubSubscription(false)),
    spy.override,
  ]);
  addTearDown(container.dispose);

  await t.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: mapleThemeData(DesignTheme.fog),
      home: const Scaffold(body: ProfileScreenV2()),
    ),
  ));
  await t.pump(const Duration(milliseconds: 50));

  final line = find.textContaining('Canadian data: v$kEmbeddedPackVersion');
  await t.ensureVisible(line);
  expect(line, findsOneWidget);
  expect(find.textContaining('built-in'), findsOneWidget);
});
```

with imports added: `package:maple_alerts/engine/canadian_data_engine/canadian_data_engine.dart`.

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/features/reminders/presentation/screens/profile_screen_v2_test.dart`
Expected: new test FAILS (text not found).

- [ ] **Step 3: Implement**

In `profile_screen_v2.dart`, in `build` add `final pack = ref.watch(dataPackProvider);` (import `package:maple_alerts/providers/data_pack_provider.dart` and the engine barrel for `EmbeddedDataPack`), and directly after the Privacy caption `Padding` (the 'Helps us decide…' text), add:

```dart
Padding(
  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
  child: Text(
    'Canadian data: v${pack.packVersion}'
    '${pack is EmbeddedDataPack ? ' · built-in' : ' · updated over the air'}',
    style: TextStyle(fontSize: 11, color: colors.faint),
  ),
),
```

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/features/reminders/presentation/screens/profile_screen_v2_test.dart`
Expected: PASS (all tests in the file).

- [ ] **Step 5: Commit**

```bash
git add lib/features/reminders/presentation/screens/profile_screen_v2.dart test/features/reminders/presentation/screens/profile_screen_v2_test.dart
git commit -m "feat: data-pack version trust line in You > Privacy"
```

---

### Task 6: Full verification + live pipe check + docs

**Files:**
- Modify: `build-status.md`

- [ ] **Step 1: Full suite + analyzer**

Run: `flutter test` → Expected: ALL pass (290+).
Run: `flutter analyze` → Expected: 0 warnings/errors (the 14 pre-existing info lints in old V1 screens/tests are known).

- [ ] **Step 2: Push, then verify the hosted pack is live**

```bash
git push
```

Wait for the Pages deploy (~1–2 min), then:

Run: `curl -s https://sss09.github.io/MapleAlerts/datapack/pack.json | Select-Object -First 3` (PowerShell: `(Invoke-WebRequest https://sss09.github.io/MapleAlerts/datapack/pack.json).Content.Substring(0,200)`)
Expected: the pack JSON with `"schemaVersion": 1`. If 404, check whether `pages.yml` deploys `build/web` from a `flutter build web` (then the file ships next deploy) and report the workflow's actual mechanism.

- [ ] **Step 3: Live smoke**

Run: `flutter run -d chrome --web-port 8088`, open You → Privacy: expect `Canadian data: v2026-06-02 · built-in` (the hosted pack equals embedded, so embedded wins — correct). The over-the-air path was proven by tests; it activates the first time the hosted `packVersion` is bumped past the embedded one.

- [ ] **Step 4: Update build-status.md**

Add a "Hosted data pack — DONE" section under Build Progress (mechanism, ops loop, pack URL) and a session-history line. Include the ops reminder: **December 2026 = first real pack update** (CRA's 2027 limits).

- [ ] **Step 5: Commit + push**

```bash
git add build-status.md
git commit -m "docs: build-status - hosted data pack slice"
git push
```

---

## Self-review notes

- **Spec coverage:** schema+packVersion gates (T1), per-field fallback (T1), generator + identical-data v1 + sanity test (T2), service fetch/cache/TTL/fail-soft (T3), resolution + 6-site swap + startup hook + `cachedPackJsonProvider` (T4), trust line (T5), ops loop documented + live URL check (T6). Deferred items in spec (signing, ETag, explainer figures) intentionally have no tasks.
- **Type consistency:** `RemoteDataPack.fromJson(Map<String,dynamic>, {required DataPack fallback})` used identically in T1/T2/T3/T4; `kEmbeddedPackVersion` defined T1, referenced T2/T4/T5; `PackFetcher`/`DataPackService(fetch:, now:)` consistent T3/T4.
- **Risk note:** `EmbeddedDataPack.packVersion` changes value (was `tfsa-embedded-2026.1`) — T1 Step 5 runs the whole engine suite to catch any test pinning the old string; the known TFSA test only asserts non-empty.
