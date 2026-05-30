import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/revenue_cat_service.dart';

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<bool>>((ref) {
  return SubscriptionNotifier();
});

class SubscriptionNotifier extends StateNotifier<AsyncValue<bool>> {
  SubscriptionNotifier() : super(const AsyncValue.loading()) {
    _check();
  }

  Future<void> _check() async {
    state = await AsyncValue.guard(() => RevenueCatService.instance.isPremium());
  }

  Future<bool> purchase() async {
    final success = await RevenueCatService.instance.purchasePremium();
    if (success) state = const AsyncValue.data(true);
    return success;
  }

  Future<bool> restore() async {
    final success = await RevenueCatService.instance.restorePurchases();
    if (success) state = const AsyncValue.data(true);
    return success;
  }

  Future<void> refresh() => _check();
}
