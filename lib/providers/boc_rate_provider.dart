import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/boc_rate_service.dart';

final bocRateServiceProvider = Provider<BocRateService>((ref) => BocRateService());

/// The current BoC policy rate — fetched live, falling back to the cached value
/// (or null) when offline. Invalidate to refresh.
final bocRateProvider = FutureProvider<BocRate?>((ref) {
  return ref.watch(bocRateServiceProvider).refresh();
});
