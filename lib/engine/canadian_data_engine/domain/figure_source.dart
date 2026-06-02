/// A single labelled figure with its provenance, used to power the
/// "How we got this" trust expansion on every money insight.
///
/// Pure data — no Flutter, no formatting logic beyond what the caller passes.
class FigureSource {
  /// Human label, e.g. "2026 TFSA limit".
  final String label;

  /// Display value, e.g. "$7,000" or "2018".
  final String value;

  /// Where the number came from, e.g. "CRA" or "Your input".
  final String source;

  const FigureSource(this.label, this.value, this.source);

  @override
  bool operator ==(Object other) =>
      other is FigureSource &&
      other.label == label &&
      other.value == value &&
      other.source == source;

  @override
  int get hashCode => Object.hash(label, value, source);

  @override
  String toString() => 'FigureSource($label: $value · $source)';
}
