import 'package:purchases_flutter/purchases_flutter.dart';

import '../utils/constants.dart';

class RevenueCatService {
  RevenueCatService._();
  static final RevenueCatService instance = RevenueCatService._();

  Future<void> initialize() async {
    try {
      final configuration = PurchasesConfiguration(kRevenueCatApiKey);
      await Purchases.configure(configuration);
    } catch (e) {
      // Silently fail — app still works in free mode
    }
  }

  Future<bool> isPremium() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active
          .containsKey(kRevenueCatEntitlement);
    } catch (e) {
      return false;
    }
  }

  Future<bool> purchasePremium() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return false;

      // Use the first available monthly package
      final monthlyPackage = current.monthly;
      if (monthlyPackage == null) {
        // Fall back to first available package
        final packages = current.availablePackages;
        if (packages.isEmpty) return false;
        final customerInfo =
            await Purchases.purchasePackage(packages.first);
        return customerInfo.entitlements.active
            .containsKey(kRevenueCatEntitlement);
      }

      final customerInfo = await Purchases.purchasePackage(monthlyPackage);
      return customerInfo.entitlements.active
          .containsKey(kRevenueCatEntitlement);
    } catch (e) {
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.active
          .containsKey(kRevenueCatEntitlement);
    } catch (e) {
      return false;
    }
  }
}
