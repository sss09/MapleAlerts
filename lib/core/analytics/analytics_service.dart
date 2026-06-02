/// Where events go in production (Aptabase) or tests (a spy).
typedef AnalyticsSink = void Function(String event, Map<String, Object> props);

/// The single choke point for anonymous product analytics.
///
/// - Fire-and-forget: [track] never throws and never awaits — an analytics
///   failure must never affect the UX.
/// - Kill switch: [isEnabled] is read per call, so flipping the Privacy
///   toggle takes effect immediately without rebuilding the service.
/// - Session de-dupe: view-type events fire once per subject per app session
///   (widget rebuilds would otherwise swamp the signal).
/// - PII guard: property names are asserted against [kDeniedPropKeys] in
///   debug builds — the hard "never sent" contract from the spec.
class AnalyticsService {
  AnalyticsService({required AnalyticsSink sink, required this.isEnabled})
      : _sink = sink;

  final AnalyticsSink _sink;
  final bool Function() isEnabled;
  final Set<String> _seenViews = {};

  /// Property names that must never appear on any event — the spec's
  /// "never sent" denylist. Topic names and card ids only; never numbers,
  /// never identity, never location.
  static const Set<String> kDeniedPropKeys = {
    'amount', 'income', 'value', 'title', 'birthyear', 'birth_year',
    'province', 'kids', 'contributed', 'email', 'name',
  };

  /// Events de-duped once per subject per session, keyed by these props.
  static const Map<String, List<String>> _dedupeKeys = {
    'insight_card_viewed': ['id'],
    'best_move_shown': ['kind', 'target'],
  };

  void track(String event, [Map<String, Object> props = const {}]) {
    // PII guard runs even when disabled — a call site that leaks PII is a bug
    // regardless of the toggle state, and must be caught in debug builds.
    assert(
      props.keys.every((k) => !kDeniedPropKeys.contains(k.toLowerCase())),
      'Denylisted analytics property on "$event": ${props.keys}',
    );
    if (!isEnabled()) return;
    final dedupeBy = _dedupeKeys[event];
    if (dedupeBy != null) {
      assert(
        dedupeBy.every((k) => props.containsKey(k)),
        'De-dupe event "$event" is missing required prop(s): '
        '${dedupeBy.where((k) => !props.containsKey(k)).toList()}',
      );
      final key = '$event|${dedupeBy.map((k) => props[k] ?? '').join('|')}';
      if (!_seenViews.add(key)) return;
    }
    try {
      _sink(event, props);
    } catch (_) {
      // Fire-and-forget: analytics must never break the app.
    }
  }
}
