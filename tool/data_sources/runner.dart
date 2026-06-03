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
