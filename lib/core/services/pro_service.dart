import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import 'purchases_config.dart';

/// Lightweight adapter that wraps a RevenueCat [Package] and exposes only the
/// fields the UI actually needs, keeping the paywall screen decoupled from the
/// SDK's internal types.
class PurchasePackage {
  final String id;
  final String priceString;
  final double rawPrice;
  final String title;

  // Internal — not part of the public API surface but accessible within the
  // service layer for passing directly to Purchases.purchasePackage().
  final Package rcPackage;

  const PurchasePackage._({
    required this.id,
    required this.priceString,
    required this.rawPrice,
    required this.title,
    required this.rcPackage,
  });

  factory PurchasePackage._fromRcPackage(Package pkg) {
    return PurchasePackage._(
      id: pkg.storeProduct.identifier,
      priceString: pkg.storeProduct.priceString,
      rawPrice: pkg.storeProduct.price,
      title: pkg.storeProduct.title,
      rcPackage: pkg,
    );
  }
}

class ProService {
  final SharedPreferences _prefs;

  bool _isPro = false;
  PurchasePackage? _monthlyProduct;
  PurchasePackage? _annualProduct;

  ProService(this._prefs);

  bool get isProUser => _isPro;

  /// All loaded packages — kept for callers that iterate `products`.
  List<PurchasePackage> get products => [
        if (_monthlyProduct != null) _monthlyProduct!,
        if (_annualProduct != null) _annualProduct!,
      ];

  PurchasePackage? get monthlyProduct => _monthlyProduct;
  PurchasePackage? get annualProduct => _annualProduct;

  Future<void> initialize() async {
    // Restore cached Pro status — works offline / on cold start.
    _isPro = _prefs.getBool(AppConstants.keyIsPro) ?? false;

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);

      final configuration = PurchasesConfiguration(
        Platform.isIOS ? PurchasesConfig.iosApiKey : PurchasesConfig.androidApiKey,
      );
      await Purchases.configure(configuration);

      // Keep _isPro in sync whenever RevenueCat sends a CustomerInfo update
      // (e.g. after a background renewal or restore).
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdate);

      await reloadProducts();
    } catch (e) {
      debugPrint('[ProService] initialize error: $e');
    }
  }

  /// Called after Firebase sign-in so RevenueCat links purchases to the user.
  Future<void> identify(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      debugPrint('[ProService] identify error: $e');
    }
  }

  /// Called on sign-out so RevenueCat returns to anonymous mode.
  Future<void> logOut() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint('[ProService] logOut error: $e');
    }
  }

  /// Fetches offerings from RevenueCat and extracts monthly / annual packages
  /// from the default offering.
  Future<void> reloadProducts() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.getOffering(AppConstants.defaultOfferingId)
          ?? offerings.current;

      if (offering == null) {
        debugPrint('[ProService] reloadProducts: no offerings available');
        return;
      }

      final packages = offering.availablePackages;

      _monthlyProduct = _packageByType(offering, PackageType.monthly)
          ?? _packageByType(offering, PackageType.weekly)
          ?? (packages.isNotEmpty ? PurchasePackage._fromRcPackage(packages.first) : null);

      _annualProduct = _packageByType(offering, PackageType.annual)
          ?? (packages.length > 1 ? PurchasePackage._fromRcPackage(packages[1]) : null);

      debugPrint('[ProService] loaded: monthly=${_monthlyProduct?.priceString}, annual=${_annualProduct?.priceString}');
    } catch (e) {
      debugPrint('[ProService] reloadProducts error: $e');
    }
  }

  /// Initiates a purchase flow for [package] via RevenueCat.
  Future<PurchaseResult> purchaseProduct(PurchasePackage package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package.rcPackage);
      final entitled = customerInfo
          .entitlements
          .active
          .containsKey(AppConstants.proEntitlementId);

      if (entitled) {
        _isPro = true;
        await _prefs.setBool(AppConstants.keyIsPro, true);
        return PurchaseResult.success;
      }
      return PurchaseResult.notEntitled;
    } on PurchasesErrorCode catch (code) {
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult.cancelled;
      }
      debugPrint('[ProService] purchaseProduct error code: $code');
      return PurchaseResult.error;
    } catch (e) {
      debugPrint('[ProService] purchaseProduct error: $e');
      return PurchaseResult.error;
    }
  }

  /// Restores previous purchases. Returns `true` if the user is now Pro.
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      final entitled = customerInfo
          .entitlements
          .active
          .containsKey(AppConstants.proEntitlementId);

      _isPro = entitled;
      await _prefs.setBool(AppConstants.keyIsPro, entitled);
      return entitled;
    } catch (e) {
      debugPrint('[ProService] restorePurchases error: $e');
      return false;
    }
  }

  /// Debug-only: activate Pro locally without a real purchase.
  Future<void> debugActivatePro() async {
    assert(() {
      _isPro = true;
      _prefs.setBool(AppConstants.keyIsPro, true);
      return true;
    }());
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  void _onCustomerInfoUpdate(CustomerInfo customerInfo) {
    final entitled = customerInfo
        .entitlements
        .active
        .containsKey(AppConstants.proEntitlementId);
    _isPro = entitled;
    _prefs.setBool(AppConstants.keyIsPro, entitled);
  }

  PurchasePackage? _packageById(Offering offering, String productId) {
    for (final pkg in offering.availablePackages) {
      if (pkg.storeProduct.identifier == productId) {
        return PurchasePackage._fromRcPackage(pkg);
      }
    }
    return null;
  }

  PurchasePackage? _packageByType(Offering offering, PackageType type) {
    for (final pkg in offering.availablePackages) {
      if (pkg.packageType == type) {
        return PurchasePackage._fromRcPackage(pkg);
      }
    }
    return null;
  }

  void dispose() {
    Purchases.removeCustomerInfoUpdateListener(_onCustomerInfoUpdate);
  }
}

enum PurchaseResult { success, cancelled, notEntitled, error }
