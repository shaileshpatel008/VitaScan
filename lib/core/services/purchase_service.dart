import 'dart:async';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/datasources/local_datasource.dart';
import '../../data/models/store_product.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../constants/storage_keys.dart';
import '../utils/app_logger.dart';
import '../utils/app_messenger.dart';
import '../utils/premium_policy.dart';

/// In-app purchases without any login: purchases belong to the user's Google
/// Play account (Apple ID on iOS), so they come back after a reinstall or on a
/// new phone signed in to the same account.
///
/// Android: Premium is re-checked with Google Play on every launch
/// (`queryPastPurchases` only returns active purchases), so cancelled or expired
/// subscriptions are removed automatically.
///
/// iOS: StoreKit restore also returns expired subscriptions, so expiry can't be
/// checked without receipt validation. Add server-side validation (or a service
/// such as RevenueCat) before launching subscriptions on the App Store.
class PurchaseService extends GetxService {
  PurchaseService(this._local);

  final LocalDataSource _local;
  final _iap = InAppPurchase.instance;
  static const _secure = FlutterSecureStorage();

  final plan = PremiumPlan.none.obs;
  final freeScansUsed = 0.obs;
  final products = <StoreProduct>[].obs;
  final storeAvailable = false.obs;
  final loadingProducts = false.obs;
  final purchasing = false.obs;
  final restoring = false.obs;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _manualRestore = false;
  bool _restoreFound = false;

  bool get isPremium => plan.value.isActive;

  /// Whether ads should be hidden (for when ads are added).
  bool get adsRemoved => isPremium;

  ScanAllowance get allowance => ScanAllowance(used: freeScansUsed.value, isPremium: isPremium);

  Future<PurchaseService> init() async {
    plan.value = PremiumPlan.fromName(_local.readPremium()?['plan'] as String?);
    try {
      freeScansUsed.value = int.tryParse(await _secure.read(key: StorageKeys.freeScansUsed) ?? '') ?? 0;
    } catch (e) {
      AppLogger.error('Free scan counter unreadable', e);
    }
    _sub = _iap.purchaseStream.listen(_onPurchases, onError: (Object e) => AppLogger.error('Purchase stream error', e));
    // Don't block app start-up on the store.
    unawaited(_connect());
    return this;
  }

  Future<void> _connect() async {
    try {
      storeAvailable.value = await _iap.isAvailable();
      if (!storeAvailable.value) return;
      await Future.wait([loadProducts(), refreshEntitlement()]);
    } catch (e, st) {
      AppLogger.error('Store connection failed', e, st);
    }
  }

  // ---------------------------------------------------------------- products

  Future<void> loadProducts() async {
    if (loadingProducts.value) return;
    loadingProducts.value = true;
    try {
      if (!storeAvailable.value) storeAvailable.value = await _iap.isAvailable();
      if (!storeAvailable.value) return;
      final response = await _iap.queryProductDetails(AppConstants.premiumProductIds);
      if (response.error != null) AppLogger.error('Product query error: ${response.error}');
      if (response.notFoundIDs.isNotEmpty) AppLogger.debug('Products not found: ${response.notFoundIDs}');
      products.assignAll(StoreProduct.pickBestOffers(response.productDetails));
    } catch (e, st) {
      AppLogger.error('Loading products failed', e, st);
    } finally {
      loadingProducts.value = false;
    }
  }

  // ---------------------------------------------------------------- entitlement

  /// Re-checks what the user owns. On Android this also revokes Premium when a
  /// subscription has ended. Offline or store errors keep the cached status.
  Future<void> refreshEntitlement() async {
    if (!Platform.isAndroid) return;
    final addition = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await addition.queryPastPurchases();
    if (response.error != null) {
      AppLogger.error('Purchase query failed, keeping cached status: ${response.error}');
      return;
    }
    final owned = <String>[];
    for (final p in response.pastPurchases) {
      if (p.billingClientPurchase.purchaseState != PurchaseStateWrapper.purchased) continue;
      owned.add(p.productID);
      // Purchases must be acknowledged within 3 days or Google refunds them.
      if (!p.billingClientPurchase.isAcknowledged) await _iap.completePurchase(p);
    }
    await _setPlan(PremiumPlan.fromOwned(owned));
  }

  Future<void> _setPlan(PremiumPlan value) async {
    plan.value = value;
    await _local.writePremium({'plan': value.name, 'checkedAt': DateTime.now().toIso8601String()});
  }

  // ---------------------------------------------------------------- free scans

  /// Call after each successful scan. Returns true if that used the last free scan.
  Future<bool> recordSuccessfulScan() async {
    if (isPremium) return false;
    final wasLast = allowance.isLastFreeScan;
    freeScansUsed.value++;
    try {
      await _secure.write(key: StorageKeys.freeScansUsed, value: '${freeScansUsed.value}');
    } catch (e) {
      AppLogger.error('Saving free scan counter failed', e);
    }
    return wasLast;
  }

  // ---------------------------------------------------------------- buying

  Future<void> buy(StoreProduct product) async {
    if (purchasing.value) return;
    if (!storeAvailable.value) {
      AppMessenger.warning(AppStrings.premiumStoreUnavailable, title: 'Store unavailable');
      return;
    }
    purchasing.value = true;
    try {
      final param = Platform.isAndroid
          ? GooglePlayPurchaseParam(productDetails: product.details)
          : PurchaseParam(productDetails: product.details);
      // Subscriptions and the lifetime unlock are both non-consumable.
      final started = await _iap.buyNonConsumable(purchaseParam: param);
      if (!started) purchasing.value = false;
    } catch (e, st) {
      AppLogger.error('Starting purchase failed', e, st);
      purchasing.value = false;
      AppMessenger.error(AppStrings.premiumFailed, title: 'Purchase not completed');
    }
  }

  Future<void> restore() async {
    if (restoring.value) return;
    restoring.value = true;
    try {
      if (Platform.isAndroid) {
        await refreshEntitlement();
        if (isPremium) {
          AppMessenger.success(AppStrings.premiumRestored, title: 'Purchase restored');
        } else {
          AppMessenger.info(AppStrings.premiumNothingToRestore, title: 'Nothing to restore');
        }
      } else {
        _manualRestore = true;
        _restoreFound = false;
        await _iap.restorePurchases();
        // Restored purchases arrive on the purchase stream.
        await Future.delayed(const Duration(seconds: 4));
        if (_manualRestore && !_restoreFound) {
          AppMessenger.info(AppStrings.premiumNothingToRestore, title: 'Nothing to restore');
        }
        _manualRestore = false;
      }
    } catch (e, st) {
      AppLogger.error('Restore failed', e, st);
      AppMessenger.warning(AppStrings.premiumStoreUnavailable, title: 'Couldn\'t restore');
    } finally {
      restoring.value = false;
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> updates) async {
    for (final p in updates) {
      final purchasedPlan = PremiumPlan.fromProductId(p.productID);
      switch (p.status) {
        case PurchaseStatus.pending:
          AppMessenger.info(AppStrings.premiumPending, title: 'Payment pending');
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (purchasedPlan.isActive && purchasedPlan.index >= plan.value.index) await _setPlan(purchasedPlan);
          if (p.status == PurchaseStatus.purchased) {
            AppMessenger.success(AppStrings.premiumWelcomeBody, title: AppStrings.premiumWelcomeTitle);
          } else if (_manualRestore && !_restoreFound) {
            _restoreFound = true;
            AppMessenger.success(AppStrings.premiumRestored, title: 'Purchase restored');
          }
        case PurchaseStatus.error:
          AppLogger.error('Purchase error: ${p.error}');
          AppMessenger.error(AppStrings.premiumFailed, title: 'Purchase not completed');
        case PurchaseStatus.canceled:
          AppMessenger.info(AppStrings.premiumCancelled, title: 'Purchase cancelled');
      }
      if (p.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(p);
        } catch (e, st) {
          AppLogger.error('Completing purchase failed', e, st);
        }
      }
      if (p.status != PurchaseStatus.pending) purchasing.value = false;
    }
  }

  /// Opens the store's subscription management page.
  Future<void> manageSubscription() async {
    final url = Platform.isAndroid
        ? 'https://play.google.com/store/account/subscriptions?package=${AppConstants.androidPackageName}'
        : 'https://apps.apple.com/account/subscriptions';
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
