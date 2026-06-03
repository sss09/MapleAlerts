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
