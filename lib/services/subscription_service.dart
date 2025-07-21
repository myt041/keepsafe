import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];

  // Product IDs - you'll need to set these up in App Store/Play Console
  static const String _monthlySubscriptionId = 'keepsafe_pro_monthly';
  static const String _yearlySubscriptionId = 'keepsafe_pro_yearly';

  // SharedPreferences keys
  static const String _isProUserKey = 'is_pro_user';
  static const String _subscriptionExpiryKey = 'subscription_expiry';
  static const String _purchaseTokenKey = 'purchase_token';

  // Stream controllers for UI updates
  final StreamController<bool> _proStatusController =
      StreamController<bool>.broadcast();
  Stream<bool> get proStatusStream => _proStatusController.stream;

  bool _isProUser = false;
  DateTime? _subscriptionExpiry;

  // Getters
  bool get isProUser => _isProUser;
  DateTime? get subscriptionExpiry => _subscriptionExpiry;
  List<ProductDetails> get products => _products;

  // Initialize the subscription service
  Future<void> initialize() async {
    await _loadSubscriptionStatus();
    await _initializeInAppPurchase();
  }

  // Load saved subscription status
  Future<void> _loadSubscriptionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isProUser = prefs.getBool(_isProUserKey) ?? false;

      final expiryString = prefs.getString(_subscriptionExpiryKey);
      if (expiryString != null) {
        _subscriptionExpiry = DateTime.parse(expiryString);

        // Check if subscription has expired
        if (_subscriptionExpiry!.isBefore(DateTime.now())) {
          _isProUser = false;
          await _saveSubscriptionStatus(false, null);
        }
      }

      _proStatusController.add(_isProUser);
    } catch (e) {
      debugPrint('Error loading subscription status: $e');
    }
  }

  // Save subscription status
  Future<void> _saveSubscriptionStatus(bool isPro, DateTime? expiry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isProUserKey, isPro);

      if (expiry != null) {
        await prefs.setString(_subscriptionExpiryKey, expiry.toIso8601String());
      } else {
        await prefs.remove(_subscriptionExpiryKey);
      }

      _isProUser = isPro;
      _subscriptionExpiry = expiry;
      _proStatusController.add(_isProUser);
    } catch (e) {
      debugPrint('Error saving subscription status: $e');
    }
  }

  // Initialize in-app purchase
  Future<void> _initializeInAppPurchase() async {
    try {
      // Check if in-app purchases are available
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        debugPrint('In-app purchases not available');
        return;
      }

      // Set up purchase stream
      _subscription = _inAppPurchase.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription.cancel(),
        onError: (error) => debugPrint('Purchase stream error: $error'),
      );

      // Load products
      await _loadProducts();
    } catch (e) {
      debugPrint('Error initializing in-app purchase: $e');
    }
  }

  // Load available products
  Future<void> _loadProducts() async {
    try {
      final Set<String> productIds = {
        _monthlySubscriptionId,
        _yearlySubscriptionId,
      };

      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }

      if (response.productDetails.isNotEmpty) {
        _products = response.productDetails;
        debugPrint('Loaded ${_products.length} products');
      }
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  // Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Handle pending purchase
        debugPrint('Purchase pending: ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Handle error
        debugPrint('Purchase error: ${purchaseDetails.error}');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Handle successful purchase
        _handleSuccessfulPurchase(purchaseDetails);
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchaseDetails);
      }
    }
  }

  // Handle successful purchase
  void _handleSuccessfulPurchase(PurchaseDetails purchaseDetails) async {
    try {
      debugPrint('Purchase successful: ${purchaseDetails.productID}');

      // Calculate subscription expiry
      DateTime? expiry;
      if (purchaseDetails.productID == _monthlySubscriptionId) {
        expiry = DateTime.now().add(const Duration(days: 30));
      } else if (purchaseDetails.productID == _yearlySubscriptionId) {
        expiry = DateTime.now().add(const Duration(days: 365));
      }

      // Save purchase token for verification (optional)
      if (purchaseDetails.purchaseID != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_purchaseTokenKey, purchaseDetails.purchaseID!);
      }

      // Update subscription status
      await _saveSubscriptionStatus(true, expiry);

      debugPrint('Subscription activated until: $expiry');
    } catch (e) {
      debugPrint('Error handling successful purchase: $e');
    }
  }

  // Purchase a subscription
  Future<bool> purchaseSubscription(String productId) async {
    try {
      final ProductDetails product = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found'),
      );

      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: product);

      bool success = false;
      if (productId == _monthlySubscriptionId ||
          productId == _yearlySubscriptionId) {
        success =
            await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      }

      return success;
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      return false;
    }
  }

  // Restore purchases (iOS)
  Future<bool> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }

  // Check if user can add more family members
  bool canAddFamilyMember(int currentCount) {
    if (_isProUser) return true;
    return currentCount < 3; // Free tier limit: user + 2 family members
  }

  // Get subscription status text
  String getSubscriptionStatusText() {
    if (!_isProUser) {
      return 'Free Plan';
    }

    if (_subscriptionExpiry != null) {
      final daysLeft = _subscriptionExpiry!.difference(DateTime.now()).inDays;
      if (daysLeft > 0) {
        return 'Pro Plan (${daysLeft} days left)';
      } else {
        return 'Pro Plan (Expired)';
      }
    }

    return 'Pro Plan';
  }

  // Dispose resources
  void dispose() {
    _subscription.cancel();
    _proStatusController.close();
  }
}
