import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maple_alerts/core/analytics/analytics_service.dart';
import 'package:maple_alerts/providers/analytics_provider.dart';

/// Spy used by widget tests: records every event, never touches the network.
class AnalyticsSpy {
  final List<(String, Map<String, Object>)> events = [];

  late final AnalyticsService service = AnalyticsService(
    sink: (e, p) => events.add((e, p)),
    isEnabled: () => true,
  );

  Override get override => analyticsProvider.overrideWithValue(service);

  bool fired(String event) => events.any((r) => r.$1 == event);

  Map<String, Object>? propsOf(String event) {
    for (final r in events) {
      if (r.$1 == event) return r.$2;
    }
    return null;
  }
}
