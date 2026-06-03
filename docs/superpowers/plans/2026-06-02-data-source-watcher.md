# Data-Source Watcher Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A scheduled job watches CRA source pages for the indexed single-number figures, and opens a PR with a regenerated `pack.json` when one changes (or an issue when a page can't be parsed) — removing the manual "watch + type" work while keeping a human merge gate.

**Architecture:** Pure parsers (`htmlBody → num?`) + per-source sanity bands form the testable core; a runner fetches each source, applies the band, diffs against the current `web/datapack/pack.json`, regenerates the pack on an in-band change, and signals via exit code (10=change, 20=parse-failure, 0=quiet); a GitHub Action branches that into a PR or an issue. Spec: `docs/superpowers/specs/2026-06-02-data-source-watcher-design.md`.

**Tech Stack:** Dart (`dart run`, no Flutter needed for the tool), `http` + `html` packages, GitHub Actions (`peter-evans/create-pull-request`, `actions/github-script`).

**Conventions:** PowerShell — chain with `;`. Strict TDD. Parsers are pure + offline (fixtures, never live fetches in tests). Tool code lives under `tool/`, tests under `test/tool/`. Commit per task. Work on `main`.

**IMPORTANT for the implementer:** the exact CRA page HTML is not known at plan-writing time. Where a step says "author the regex against the captured fixture", you must (a) capture the live page into a fixture file as instructed, (b) read it, (c) write a parser whose pattern anchors on stable visible text near the figure, then (d) make the fixture-based test pass. Do NOT invent figures — extract them from the captured HTML.

---

### Task 1: `WatchedSource` model + sanity-band logic (TDD)

**Files:**
- Create: `tool/data_sources/source.dart`
- Test: `test/tool/source_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:maple_alerts/../tool/data_sources/source.dart';

void main() {
  num? always7000(String _) => 7000;
  num? alwaysNull(String _) => null;

  WatchedSource src(num? Function(String) parser) => WatchedSource(
        id: 'tfsa',
        label: 'TFSA annual limit',
        url: Uri.parse('https://example.test/tfsa'),
        parse: parser,
        min: 5000,
        max: 20000,
        step: 500,
      );

  group('WatchedSource.evaluate', () {
    test('in-band value equal to current → noChange', () {
      final r = src(always7000).evaluate('<html/>', current: 7000);
      expect(r.kind, SourceResultKind.noChange);
      expect(r.value, 7000);
    });

    test('in-band value different from current → change', () {
      final r = src(always7000).evaluate('<html/>', current: 6500);
      expect(r.kind, SourceResultKind.change);
      expect(r.value, 7000);
    });

    test('parser returns null → failure', () {
      final r = src(alwaysNull).evaluate('<html/>', current: 7000);
      expect(r.kind, SourceResultKind.failure);
      expect(r.reason, contains('could not parse'));
    });

    test('value below min → failure (misparse guard)', () {
      final r = src((_) => 100).evaluate('<html/>', current: 7000);
      expect(r.kind, SourceResultKind.failure);
      expect(r.reason, contains('out of range'));
    });

    test('value above max → failure (the \$75,000 guard)', () {
      final r = src((_) => 75000).evaluate('<html/>', current: 7000);
      expect(r.kind, SourceResultKind.failure);
    });

    test('value violating step → failure', () {
      final r = src((_) => 7200).evaluate('<html/>', current: 7000);
      expect(r.kind, SourceResultKind.failure);
      expect(r.reason, contains('step'));
    });

    test('null step skips the step check', () {
      final s = WatchedSource(
        id: 'oas', label: 'OAS', url: Uri.parse('https://x.test'),
        parse: (_) => 95000, min: 50000, max: 200000, step: null);
      final r = s.evaluate('<html/>', current: 93454);
      expect(r.kind, SourceResultKind.change);
    });
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/tool/source_test.dart`
Expected: FAIL — `source.dart` does not exist.

- [ ] **Step 3: Implement**

`tool/data_sources/source.dart`:

```dart
/// Outcome category for evaluating one watched source.
enum SourceResultKind { noChange, change, failure }

/// Result of evaluating a [WatchedSource] against fetched HTML.
class SourceResult {
  final SourceResultKind kind;
  final num? value;     // parsed value when kind != failure
  final num? previous;  // the current pack value compared against
  final String? reason; // human reason when kind == failure
  const SourceResult(this.kind, {this.value, this.previous, this.reason});
}

/// One CRA figure to watch: where it lives, how to extract it, and the
/// plausible band that guards against a misparse.
class WatchedSource {
  WatchedSource({
    required this.id,
    required this.label,
    required this.url,
    required this.parse,
    required this.min,
    required this.max,
    this.step,
  });

  /// Stable id, also the key the runner uses to route into the pack.
  final String id;
  final String label;
  final Uri url;

  /// Pure extractor: page body → figure, or null when not found.
  final num? Function(String htmlBody) parse;

  /// Plausible bounds; a parsed value outside [min, max] is treated as a
  /// misparse (failure), never a real change.
  final num min;
  final num max;

  /// When set, the value must be an exact multiple of [step] (e.g. TFSA $500).
  final num? step;

  SourceResult evaluate(String htmlBody, {required num current}) {
    final v = parse(htmlBody);
    if (v == null) {
      return SourceResult(SourceResultKind.failure,
          reason: '$label: could not parse a figure from the page');
    }
    if (v < min || v > max) {
      return SourceResult(SourceResultKind.failure,
          previous: current,
          reason: '$label: parsed $v is out of range [$min, $max]');
    }
    if (step != null && (v % step!) != 0) {
      return SourceResult(SourceResultKind.failure,
          previous: current,
          reason: '$label: parsed $v violates step $step');
    }
    if (v == current) {
      return SourceResult(SourceResultKind.noChange, value: v, previous: current);
    }
    return SourceResult(SourceResultKind.change, value: v, previous: current);
  }
}
```

NOTE the import path in the test: tool code isn't under `lib/`, so it can't be imported as a `package:` URI. Use a RELATIVE import in the test instead — replace the test's import line with `import '../../tool/data_sources/source.dart';`. (Adjust depth so it resolves from `test/tool/`.) Verify the relative path resolves; fix if the analyzer complains.

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/tool/source_test.dart`
Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
git add tool/data_sources/source.dart test/tool/source_test.dart
git commit -m "feat(watcher): WatchedSource + sanity-band evaluation"
```

---

### Task 2: Parsers + captured fixtures (TDD against real HTML)

**Files:**
- Add deps: `html` package (dev/tool use)
- Create: `tool/data_sources/parsers.dart`
- Create: `test/tool/fixtures/<source>_good.html`, `test/tool/fixtures/<source>_mangled.html`
- Test: `test/tool/parsers_test.dart`

- [ ] **Step 1: Add the html parsing dependency**

Run: `dart pub add html`
Expected: `html: ^0.15.x` added. (Used for robust DOM querying; regex is also acceptable per-parser if a figure is easier to anchor by text.)

- [ ] **Step 2: Capture live fixtures**

For each of the 5 figures, fetch the source page and save the body to a fixture. Source URLs (verify each loads; if a URL 404s, find the current CRA page for that figure and record the working URL in a comment):

- TFSA annual limit — `https://www.canada.ca/en/revenue-agency/services/tax/individuals/topics/tax-free-savings-account/contributions.html`
- RRSP dollar limit — `https://www.canada.ca/en/revenue-agency/services/tax/registered-plans-administrators/pspa/mp-rrsp-dpsp-tfsa-limits-ympe.html`
- OAS recovery threshold — `https://www.canada.ca/en/services/benefits/publicpensions/cpp/old-age-security/recovery-tax.html`
- CCB max + thresholds — `https://www.canada.ca/en/revenue-agency/services/child-family-benefits/canada-child-benefit-overview/canada-child-benefit-we-calculate-your-ccb.html`

Capture with: `dart run tool/_capture_fixture.dart <url> <outpath>` — first create that throwaway helper:

`tool/_capture_fixture.dart`:
```dart
import 'dart:io';
import 'package:http/http.dart' as http;
void main(List<String> args) async {
  final res = await http.get(Uri.parse(args[0]));
  File(args[1]).writeAsStringSync(res.body);
  stdout.writeln('Saved ${res.body.length} bytes to ${args[1]} (HTTP ${res.statusCode})');
}
```

Run it for each figure into `test/tool/fixtures/<id>_good.html`. Then for each, hand-make a `<id>_mangled.html` by deleting/garbling the figure's surrounding markup (so the parser must return null). Keep fixtures small if the pages are huge — trim to the section containing the figure (and document the trim in a comment at the top of the fixture is not possible in HTML; instead note it in parsers_test.dart).

DELETE `tool/_capture_fixture.dart` after capturing (it's a one-shot; don't ship it). Keep the fixtures.

- [ ] **Step 3: Write the failing tests** (author expected values from what you SEE in each good fixture)

`test/tool/parsers_test.dart`:
```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/data_sources/parsers.dart';

String fx(String name) =>
    File('test/tool/fixtures/$name').readAsStringSync();

void main() {
  group('parseTfsaLimit', () {
    test('extracts the current limit from the good fixture', () {
      // EXPECTED VALUE: read it from tfsa_good.html (e.g. 7000). Replace below.
      expect(parseTfsaLimit(fx('tfsa_good.html')), /* value seen in fixture */ 7000);
    });
    test('returns null on mangled markup', () {
      expect(parseTfsaLimit(fx('tfsa_mangled.html')), isNull);
    });
  });

  group('parseRrspMax', () {
    test('extracts the current dollar max', () {
      expect(parseRrspMax(fx('rrsp_good.html')), /* value seen */ 33810);
    });
    test('null on mangled', () {
      expect(parseRrspMax(fx('rrsp_mangled.html')), isNull);
    });
  });

  group('parseOasRecoveryThreshold', () {
    test('extracts the threshold', () {
      expect(parseOasRecoveryThreshold(fx('oas_good.html')), /* value seen */ 93454);
    });
    test('null on mangled', () {
      expect(parseOasRecoveryThreshold(fx('oas_mangled.html')), isNull);
    });
  });

  group('parseCcb', () {
    test('extracts maxUnder6, max6to17, threshold1, threshold2', () {
      final r = parseCcb(fx('ccb_good.html'));
      expect(r, isNotNull);
      expect(r!.maxUnder6, /* value seen */ 7997);
      expect(r.max6to17, /* value seen */ 6748);
      expect(r.threshold1, /* value seen */ 37487);
      expect(r.threshold2, /* value seen */ 81222);
    });
    test('null on mangled', () {
      expect(parseCcb(fx('ccb_mangled.html')), isNull);
    });
  });
}
```

Replace each `/* value seen */` with the actual number present in the captured good fixture.

- [ ] **Step 4: Run to verify failure**

Run: `flutter test test/tool/parsers_test.dart`
Expected: FAIL — `parsers.dart` missing.

- [ ] **Step 5: Implement the parsers**

`tool/data_sources/parsers.dart` — author each extractor against its fixture. Skeleton + the CCB result type:

```dart
/// Parsed CCB figures (subset of the engine's CcbParams that index annually).
class CcbFigures {
  final num maxUnder6;
  final num max6to17;
  final num threshold1;
  final num threshold2;
  const CcbFigures(this.maxUnder6, this.max6to17, this.threshold1, this.threshold2);
}

/// Extracts the first dollar amount near an anchor phrase, or null.
/// Helper: strips $ and commas, parses to num.
num? _money(String? raw) {
  if (raw == null) return null;
  final cleaned = raw.replaceAll(RegExp(r'[\$,\s]'), '');
  return num.tryParse(cleaned);
}

num? parseTfsaLimit(String html) {
  // Anchor on stable visible text near the figure (author from fixture).
  // e.g. match the dollar amount following the most recent year row.
  // return _money(match);
  throw UnimplementedError('author against tfsa_good.html');
}

num? parseRrspMax(String html) {
  throw UnimplementedError('author against rrsp_good.html');
}

num? parseOasRecoveryThreshold(String html) {
  throw UnimplementedError('author against oas_good.html');
}

CcbFigures? parseCcb(String html) {
  throw UnimplementedError('author against ccb_good.html');
}
```

Replace each `UnimplementedError` body with a real extractor (regex anchored on visible text, or `package:html` DOM query). Each must return null when its anchor/figure is absent (that's what the mangled-fixture test pins). Prefer anchoring on words like the benefit name or "maximum" rather than tag structure.

- [ ] **Step 6: Run to verify pass**

Run: `flutter test test/tool/parsers_test.dart`
Expected: PASS, 8 tests.

- [ ] **Step 7: Commit**

```bash
git add tool/data_sources/parsers.dart test/tool/fixtures test/tool/parsers_test.dart pubspec.yaml pubspec.lock
git commit -m "feat(watcher): CRA figure parsers + captured HTML fixtures"
```

---

### Task 3: Source registry + pack-merge helper (TDD)

**Files:**
- Create: `tool/data_sources/sources.dart`
- Create: `tool/data_sources/pack_merge.dart`
- Test: `test/tool/pack_merge_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import '../../tool/data_sources/pack_merge.dart';

void main() {
  Map<String, dynamic> base() => {
        'schemaVersion': 1,
        'packVersion': '2026-06-02',
        'tfsaAnnualLimits': {'2026': 7000},
        'rrspAnnualMax': {'2026': 33810},
        'oas': {'recoveryThreshold': 93454, 'recoveryRate': 0.15},
        'ccb': {
          'maxUnder6': 7997, 'max6to17': 6748,
          'threshold1': 37487, 'threshold2': 81222,
        },
      };

  test('currentValueFor reads the right field', () {
    final p = base();
    expect(currentValueFor(p, 'tfsa', 2027), 7000); // latest known
    expect(currentValueFor(p, 'rrsp', 2027), 33810);
    expect(currentValueFor(p, 'oas', 2027), 93454);
    expect(currentValueFor(p, 'ccb_maxUnder6', 2027), 7997);
  });

  test('applyChange writes a new figure and bumps packVersion', () {
    final p = base();
    final out = applyChange(p, {'tfsa': 7500}, year: 2027,
        newVersion: '2027-01-15');
    expect((out['tfsaAnnualLimits'] as Map)['2027'], 7500);
    expect(out['packVersion'], '2027-01-15');
    // untouched fields preserved
    expect((out['rrspAnnualMax'] as Map)['2026'], 33810);
  });

  test('applyChange updates a nested ccb field in place', () {
    final out = applyChange(base(), {'ccb_maxUnder6': 8100}, year: 2027,
        newVersion: '2027-07-01');
    expect((out['ccb'] as Map)['maxUnder6'], 8100);
  });

  test('round-trips through json without losing structure', () {
    final out = applyChange(base(), {'oas': 95000}, year: 2027,
        newVersion: '2027-01-15');
    final reparsed = jsonDecode(jsonEncode(out)) as Map<String, dynamic>;
    expect((reparsed['oas'] as Map)['recoveryThreshold'], 95000);
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/tool/pack_merge_test.dart`
Expected: FAIL — file missing.

- [ ] **Step 3: Implement**

`tool/data_sources/pack_merge.dart`:
```dart
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
```

`tool/data_sources/sources.dart` (wires parsers + bands into `WatchedSource`s; the runner imports this):
```dart
import 'parsers.dart';
import 'source.dart';

/// All watched figures (v1: indexed single-numbers; tax brackets stay manual).
/// CCB exposes four separate sources sharing one fetch (the runner caches by
/// URL so the page is fetched once).
List<WatchedSource> watchedSources() => [
      WatchedSource(
        id: 'tfsa', label: 'TFSA annual limit',
        url: Uri.parse('<TFSA url from Task 2>'),
        parse: parseTfsaLimit, min: 5000, max: 20000, step: 500),
      WatchedSource(
        id: 'rrsp', label: 'RRSP dollar maximum',
        url: Uri.parse('<RRSP url from Task 2>'),
        parse: parseRrspMax, min: 25000, max: 60000, step: 10),
      WatchedSource(
        id: 'oas', label: 'OAS recovery threshold',
        url: Uri.parse('<OAS url from Task 2>'),
        parse: parseOasRecoveryThreshold, min: 60000, max: 200000, step: null),
      WatchedSource(
        id: 'ccb_maxUnder6', label: 'CCB max (under 6)',
        url: Uri.parse('<CCB url from Task 2>'),
        parse: (h) => parseCcb(h)?.maxUnder6, min: 5000, max: 12000, step: null),
      WatchedSource(
        id: 'ccb_max6to17', label: 'CCB max (6–17)',
        url: Uri.parse('<CCB url>'),
        parse: (h) => parseCcb(h)?.max6to17, min: 4000, max: 11000, step: null),
      WatchedSource(
        id: 'ccb_threshold1', label: 'CCB phase-out threshold 1',
        url: Uri.parse('<CCB url>'),
        parse: (h) => parseCcb(h)?.threshold1, min: 25000, max: 60000, step: null),
      WatchedSource(
        id: 'ccb_threshold2', label: 'CCB phase-out threshold 2',
        url: Uri.parse('<CCB url>'),
        parse: (h) => parseCcb(h)?.threshold2, min: 60000, max: 120000, step: null),
    ];
```

Replace each `<… url>` with the working URL captured in Task 2.

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/tool/pack_merge_test.dart`
Expected: PASS, 4 tests. (sources.dart has no test of its own — it's wiring; it's exercised by the runner in Task 4.)

- [ ] **Step 5: Commit**

```bash
git add tool/data_sources/sources.dart tool/data_sources/pack_merge.dart test/tool/pack_merge_test.dart
git commit -m "feat(watcher): source registry + pure pack-merge helper"
```

---

### Task 4: The runner — fetch → evaluate → emit (TDD the decision, glue the I/O)

**Files:**
- Create: `tool/check_data_sources.dart`
- Create: `tool/data_sources/runner.dart` (pure decision, testable)
- Test: `test/tool/runner_test.dart`

- [ ] **Step 1: Write the failing tests** (the pure decision: given evaluated results, produce the outcome)

```dart
import 'package:flutter_test/flutter_test.dart';
import '../../tool/data_sources/runner.dart';
import '../../tool/data_sources/source.dart';

void main() {
  SourceResult ok(num v, num prev) =>
      SourceResult(v == prev ? SourceResultKind.noChange : SourceResultKind.change,
          value: v, previous: prev);
  SourceResult fail(String why) =>
      SourceResult(SourceResultKind.failure, reason: why);

  group('decideOutcome', () {
    test('all noChange → quiet (exit 0)', () {
      final o = decideOutcome({'tfsa': ok(7000, 7000)});
      expect(o.exitCode, 0);
      expect(o.changes, isEmpty);
      expect(o.failures, isEmpty);
    });

    test('a change, no failure → PR outcome (exit 10)', () {
      final o = decideOutcome(
          {'tfsa': ok(7500, 7000), 'rrsp': ok(33810, 33810)});
      expect(o.exitCode, 10);
      expect(o.changes, {'tfsa': 7500});
    });

    test('any failure → issue outcome (exit 20), precedence over changes', () {
      final o = decideOutcome({
        'tfsa': ok(7500, 7000),
        'oas': fail('could not parse'),
      });
      expect(o.exitCode, 20);
      expect(o.failures.length, 1);
      // changes are NOT applied when any source failed
      expect(o.changes, isEmpty);
    });

    test('summary lists each change old→new', () {
      final o = decideOutcome({'tfsa': ok(7500, 7000)});
      expect(o.summary, contains('tfsa'));
      expect(o.summary, contains('7000'));
      expect(o.summary, contains('7500'));
    });
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/tool/runner_test.dart`
Expected: FAIL — `runner.dart` missing.

- [ ] **Step 3: Implement the pure decision**

`tool/data_sources/runner.dart`:
```dart
import 'source.dart';

/// The runner's decision given each source's evaluated [SourceResult].
class Outcome {
  /// 0 = nothing, 10 = changes → PR, 20 = any failure → issue.
  final int exitCode;
  final Map<String, num> changes; // id → new value (empty unless exit 10)
  final List<String> failures;    // reasons (non-empty when exit 20)
  final String summary;           // human/PR-body text
  const Outcome(this.exitCode, this.changes, this.failures, this.summary);
}

Outcome decideOutcome(Map<String, SourceResult> results) {
  final failures = <String>[];
  final changes = <String, num>{};
  final lines = <String>[];

  results.forEach((id, r) {
    switch (r.kind) {
      case SourceResultKind.failure:
        failures.add(r.reason ?? '$id: unknown parse failure');
      case SourceResultKind.change:
        changes[id] = r.value!;
        lines.add('• $id: ${r.previous} → ${r.value}');
      case SourceResultKind.noChange:
        break;
    }
  });

  if (failures.isNotEmpty) {
    // Failure precedence: never ship a partial pack from a half-broken scrape.
    return Outcome(20, const {}, failures,
        'Data-watch could not parse:\n${failures.map((f) => '• $f').join('\n')}');
  }
  if (changes.isNotEmpty) {
    return Outcome(10, changes, const [],
        'Data-watch detected changes:\n${lines.join('\n')}');
  }
  return const Outcome(0, {}, [], 'No changes.');
}
```

- [ ] **Step 4: Run to verify pass**

Run: `flutter test test/tool/runner_test.dart`
Expected: PASS, 4 tests.

- [ ] **Step 5: Write the I/O glue (no unit test — exercised by dry run)**

`tool/check_data_sources.dart`:
```dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'data_sources/pack_merge.dart';
import 'data_sources/runner.dart';
import 'data_sources/source.dart';
import 'data_sources/sources.dart';

const _packPath = 'web/datapack/pack.json';

Future<void> main() async {
  final pack =
      jsonDecode(File(_packPath).readAsStringSync()) as Map<String, dynamic>;
  final year = DateTime.now().year;
  final sources = watchedSources();

  // Fetch each distinct URL once.
  final bodies = <String, String>{};
  final results = <String, SourceResult>{};
  for (final s in sources) {
    try {
      final key = s.url.toString();
      bodies[key] ??= await _fetch(s.url);
      final current = currentValueFor(pack, s.id, year);
      if (current == null) {
        results[s.id] = SourceResult(SourceResultKind.failure,
            reason: '${s.label}: no current value in pack to compare');
        continue;
      }
      results[s.id] = s.evaluate(bodies[key]!, current: current);
    } catch (e) {
      results[s.id] = SourceResult(SourceResultKind.failure,
          reason: '${s.label}: fetch/parse error: $e');
    }
  }

  final outcome = decideOutcome(results);
  stdout.writeln(outcome.summary);

  if (outcome.exitCode == 10) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final updated = applyChange(pack, outcome.changes,
        year: year, newVersion: today);
    File(_packPath).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(updated)}\n');
    // Expose the summary to the Action via an output file.
    File('.data-watch-summary.txt').writeAsStringSync(outcome.summary);
  } else if (outcome.exitCode == 20) {
    File('.data-watch-summary.txt').writeAsStringSync(outcome.summary);
  }
  exit(outcome.exitCode);
}

Future<String> _fetch(Uri url) async {
  final res = await http.get(url).timeout(const Duration(seconds: 10));
  if (res.statusCode != 200) {
    throw HttpException('HTTP ${res.statusCode}', uri: url);
  }
  return res.body;
}
```

- [ ] **Step 6: Dry-run it locally**

Run: `dart run tool/check_data_sources.dart; echo "exit=$LASTEXITCODE"`
(PowerShell: `dart run tool/check_data_sources.dart; "exit=$LASTEXITCODE"`)
Expected: against the current live pages it should print "No changes." and exit 0 (the pack already holds today's figures). If it exits 20, read the summary — a parser/band needs adjusting; fix and re-run. If it exits 10 because a live page genuinely moved past the embedded value, inspect the diff — that's the feature working. Revert any pack.json change from the dry run unless it's a real, verified update: `git checkout web/datapack/pack.json`.

- [ ] **Step 7: Commit**

```bash
git add tool/check_data_sources.dart tool/data_sources/runner.dart test/tool/runner_test.dart
git commit -m "feat(watcher): runner - fetch, evaluate, failure-precedence outcome"
```

---

### Task 5: GitHub Action + docs + final verification

**Files:**
- Create: `.github/workflows/data-watch.yml`
- Modify: `build-status.md`
- Modify: `.gitignore` (ignore `.data-watch-summary.txt`)

- [ ] **Step 1: Ignore the scratch summary file**

Add to `.gitignore`:
```
# data-watch runner scratch output
.data-watch-summary.txt
```

- [ ] **Step 2: Write the workflow**

`.github/workflows/data-watch.yml`:
```yaml
name: CRA Data Watch

on:
  schedule:
    # Monthly on the 1st, 13:00 UTC; the indexation windows get extra weekly
    # runs (Nov–Jan, Jun–Jul) via the broader day-of-month list.
    - cron: '0 13 1 * *'
    - cron: '0 13 1,8,15,22 11,12,1,6,7 *'
  workflow_dispatch:

permissions:
  contents: write
  pull-requests: write
  issues: write

jobs:
  watch:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.44.0'
          channel: 'stable'
          cache: true

      - run: flutter pub get

      - name: Check CRA sources
        id: check
        run: |
          set +e
          dart run tool/check_data_sources.dart
          echo "code=$?" >> "$GITHUB_OUTPUT"
        continue-on-error: true

      - name: Open PR on change
        if: steps.check.outputs.code == '10'
        uses: peter-evans/create-pull-request@v6
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          branch: data-watch/update
          title: 'data: CRA figures changed — review before merge'
          body-path: .data-watch-summary.txt
          add-paths: web/datapack/pack.json
          commit-message: 'data: update pack.json from CRA watch'

      - name: Open issue on parse failure
        if: steps.check.outputs.code == '20'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const body = fs.readFileSync('.data-watch-summary.txt', 'utf8');
            await github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: 'data-watch: could not parse a CRA source',
              body,
            });
```

- [ ] **Step 3: Validate YAML + a manual dry run**

Run: `flutter analyze` (whole repo) → Expected: 0 new warnings/errors (the 14 pre-existing infos are known).
Run full suite: `flutter test` → Expected: ALL pass (new tool tests included).
After pushing (Step 5), trigger the workflow once via the Actions tab (`workflow_dispatch`) and confirm it runs to completion with "No changes." (exit 0 → no PR/issue). Report the run result.

- [ ] **Step 4: Update build-status.md**

Add a "CRA data-source watcher — DONE" section: mechanism (watch → in-band → PR / issue), what's watched (the 5 figures), the human merge gate, and the maintenance caveat (a parser issue means CRA moved a page → update regex + fixture). Add a session-history line.

- [ ] **Step 5: Commit + push**

```bash
git add .github/workflows/data-watch.yml build-status.md .gitignore
git commit -m "feat(watcher): scheduled CRA data-watch workflow (PR on change, issue on failure)"
git push
```

- [ ] **Step 6: Trigger + verify the live workflow** (per Step 3) and report.

---

## Self-review notes

- **Spec coverage:** parsers+fixtures+sanity bands (T1, T2), source registry/scope = the 5 indexed figures (T3), runner with failure-precedence + exit codes 10/20/0 (T4), Action → PR/issue + cron windows + permissions (T5), human merge gate (T5 PR step), caveats in docs (T5). Tax brackets excluded by omission from `watchedSources()` — matches spec.
- **Placeholder note:** the `<… url>` and `/* value seen */` markers are NOT plan placeholders in the forbidden sense — they are values the implementer MUST read from the live pages/fixtures captured in Task 2 (exact HTML is unknowable at plan time). Every step says explicitly to fill them from the capture. The parser bodies are `UnimplementedError` stubs the implementer authors against real fixtures — this is the one place pre-writing code is impossible.
- **Type consistency:** `SourceResult`/`SourceResultKind` defined T1, used T4; `WatchedSource` T1 used T3; `currentValueFor`/`applyChange` T3 used T4; `decideOutcome`/`Outcome` T4 used by the runner glue + Action exit codes. CCB exposed as 4 source ids (`ccb_maxUnder6` etc.) consistently across T3 registry, T3 pack_merge, and T4.
- **Test import paths:** tool code is outside `lib/`, so tests use relative imports (`../../tool/...`) — flagged in T1.
