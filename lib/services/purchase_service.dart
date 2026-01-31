import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'storage_service.dart';

enum AppPurchaseStatus {
  notPurchased,
  pending,
  purchased,
  restored,
  error,
}

enum SubscriptionPlan {
  weekly,
  monthly,
  yearly,
  lifetime,
}

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final StorageService _storageService = StorageService();

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isPremium = false;

  // Product IDs - These should match your App Store Connect / Play Console products
  static const String weeklyProductId = 'pockify_premium_weekly';
  static const String monthlyProductId = 'pockify_premium_monthly';
  static const String yearlyProductId = 'pockify_premium_yearly';
  static const String lifetimeProductId = 'pockify_premium_lifetime';

  static const Set<String> _productIds = {
    weeklyProductId,
    monthlyProductId,
    yearlyProductId,
    lifetimeProductId,
  };

  // Pricing info (for display, actual prices come from store)
  static const Map<SubscriptionPlan, Map<String, dynamic>> planInfo = {
    SubscriptionPlan.weekly: {
      'name': 'Haftalık',
      'price_tr': '₺14.99',
      'price_usd': '\$0.99',
      'period': '/hafta',
      'trial': true,
      'trial_days': 3,
    },
    SubscriptionPlan.monthly: {
      'name': 'Aylık',
      'price_tr': '₺29.99',
      'price_usd': '\$2.99',
      'period': '/ay',
      'trial': false,
      'popular': false,
    },
    SubscriptionPlan.yearly: {
      'name': 'Yıllık',
      'price_tr': '₺149.99',
      'price_usd': '\$9.99',
      'period': '/yıl',
      'trial': true,
      'trial_days': 3,
      'popular': true,
      'savings': '%58 tasarruf',
    },
    SubscriptionPlan.lifetime: {
      'name': 'Ömür Boyu',
      'price_tr': '₺399.99',
      'price_usd': '\$24.99',
      'period': '',
      'trial': false,
      'one_time': true,
    },
  };

  // Callbacks
  Function(AppPurchaseStatus, String?)? onPurchaseStatusChanged;

  bool get isAvailable => _isAvailable;
  bool get isPremium => _isPremium;
  List<ProductDetails> get products => _products;

  Future<void> initialize() async {
    _isAvailable = await _inAppPurchase.isAvailable();

    if (!_isAvailable) {
      debugPrint('In-app purchases not available');
      return;
    }

    // Load saved premium status
    _isPremium = _storageService.getValue<bool>('is_premium') ?? false;

    // Check subscription expiry
    await _checkSubscriptionExpiry();

    // Listen to purchase updates
    _subscription = _inAppPurchase.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) {
        debugPrint('Purchase stream error: $error');
      },
    );

    // Load products
    await loadProducts();
  }

  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    final response = await _inAppPurchase.queryProductDetails(_productIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }

    _products = response.productDetails;
    debugPrint('Loaded ${_products.length} products');
  }

  ProductDetails? getProduct(SubscriptionPlan plan) {
    final productId = _getProductId(plan);
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  String _getProductId(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.weekly:
        return weeklyProductId;
      case SubscriptionPlan.monthly:
        return monthlyProductId;
      case SubscriptionPlan.yearly:
        return yearlyProductId;
      case SubscriptionPlan.lifetime:
        return lifetimeProductId;
    }
  }

  Future<bool> purchasePlan(SubscriptionPlan plan) async {
    if (!_isAvailable) {
      onPurchaseStatusChanged?.call(
        AppPurchaseStatus.error,
        'Satın alma şu anda kullanılamıyor',
      );
      return false;
    }

    final product = getProduct(plan);
    if (product == null) {
      onPurchaseStatusChanged?.call(
        AppPurchaseStatus.error,
        'Ürün bulunamadı',
      );
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      onPurchaseStatusChanged?.call(AppPurchaseStatus.pending, null);

      if (plan == SubscriptionPlan.lifetime) {
        // Non-consumable for lifetime
        return await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      } else {
        // Subscription for weekly/monthly/yearly
        return await _inAppPurchase.buyNonConsumable(
          purchaseParam: purchaseParam,
        );
      }
    } catch (e) {
      onPurchaseStatusChanged?.call(
        AppPurchaseStatus.error,
        'Satın alma başarısız: $e',
      );
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      onPurchaseStatusChanged?.call(
        AppPurchaseStatus.error,
        'Satın alma şu anda kullanılamıyor',
      );
      return;
    }

    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      onPurchaseStatusChanged?.call(
        AppPurchaseStatus.error,
        'Geri yükleme başarısız: $e',
      );
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          onPurchaseStatusChanged?.call(AppPurchaseStatus.pending, null);
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _verifyAndDeliverPurchase(purchaseDetails);
          break;

        case PurchaseStatus.error:
          onPurchaseStatusChanged?.call(
            AppPurchaseStatus.error,
            purchaseDetails.error?.message ?? 'Bilinmeyen hata',
          );
          break;

        default:
          // Cancelled or other status
          onPurchaseStatusChanged?.call(
            AppPurchaseStatus.notPurchased,
            'Satın alma iptal edildi',
          );
          break;
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _verifyAndDeliverPurchase(PurchaseDetails purchaseDetails) async {
    // Client-side verification for MVP
    // In production, you should verify the receipt with your backend

    if (purchaseDetails.status == PurchaseStatus.purchased ||
        purchaseDetails.status == PurchaseStatus.restored) {

      _isPremium = true;
      await _storageService.setValue('is_premium', true);

      // Save purchase details for expiry check
      await _storageService.setValue(
        'purchase_date',
        DateTime.now().toIso8601String(),
      );
      await _storageService.setValue(
        'product_id',
        purchaseDetails.productID,
      );

      // Save transaction ID if available
      if (purchaseDetails.purchaseID != null) {
        await _storageService.setValue('transaction_id', purchaseDetails.purchaseID!);
      }

      final status = purchaseDetails.status == PurchaseStatus.restored
          ? AppPurchaseStatus.restored
          : AppPurchaseStatus.purchased;

      onPurchaseStatusChanged?.call(status, null);
    }
  }

  Future<void> _checkSubscriptionExpiry() async {
    if (!_isPremium) return;

    final purchaseDateStr = _storageService.getValue<String>('purchase_date');
    final productId = _storageService.getValue<String>('product_id');

    if (purchaseDateStr == null || productId == null) return;

    // Lifetime never expires
    if (productId == lifetimeProductId) return;

    try {
      final purchaseDate = DateTime.parse(purchaseDateStr);
      final now = DateTime.now();
      Duration? duration;

      if (productId == weeklyProductId) {
        duration = const Duration(days: 7);
      } else if (productId == monthlyProductId) {
        duration = const Duration(days: 30);
      } else if (productId == yearlyProductId) {
        duration = const Duration(days: 365);
      }

      if (duration != null) {
        // Add a grace period of 3 days
        if (now.difference(purchaseDate) > duration + const Duration(days: 3)) {
          // Expired
          _isPremium = false;
          await _storageService.setValue('is_premium', false);
          debugPrint('Subscription expired');
        }
      }
    } catch (e) {
      debugPrint('Error checking subscription expiry: $e');
    }
  }

  // Check if user has exceeded daily limit (for free users)
  Future<bool> canDownload() async {
    if (_isPremium) return true;

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDownloadDate =
        _storageService.getValue<String>('last_download_date');
    final downloadCount =
        _storageService.getValue<int>('daily_download_count') ?? 0;

    if (lastDownloadDate != today) {
      // New day, reset counter
      await _storageService.setValue('last_download_date', today);
      await _storageService.setValue('daily_download_count', 0);
      return true;
    }

    return downloadCount < 3; // Free users get 3 downloads per day
  }

  Future<void> incrementDownloadCount() async {
    if (_isPremium) return;

    final count = _storageService.getValue<int>('daily_download_count') ?? 0;
    await _storageService.setValue('daily_download_count', count + 1);
  }

  int getRemainingDownloads() {
    if (_isPremium) return -1; // Unlimited

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDownloadDate =
        _storageService.getValue<String>('last_download_date');

    if (lastDownloadDate != today) {
      return 3;
    }

    final count = _storageService.getValue<int>('daily_download_count') ?? 0;
    return (3 - count).clamp(0, 3);
  }

  void dispose() {
    _subscription?.cancel();
  }
}
