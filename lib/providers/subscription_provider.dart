import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:keepsafe/services/subscription_service.dart';

class SubscriptionProvider with ChangeNotifier {
  final SubscriptionService _subscriptionService = SubscriptionService();

  bool _isProUser = false;
  DateTime? _subscriptionExpiry;
  List<ProductDetails> _products = [];
  bool _isLoading = false;

  // Getters
  bool get isProUser => _isProUser;
  DateTime? get subscriptionExpiry => _subscriptionExpiry;
  List<ProductDetails> get products => _products;
  bool get isLoading => _isLoading;

  // Initialize the provider
  Future<void> initialize() async {
    _setLoading(true);

    try {
      await _subscriptionService.initialize();

      // Listen to subscription status changes
      _subscriptionService.proStatusStream.listen((isPro) {
        _isProUser = isPro;
        _subscriptionExpiry = _subscriptionService.subscriptionExpiry;
        notifyListeners();
      });

      // Load initial state
      _isProUser = _subscriptionService.isProUser;
      _subscriptionExpiry = _subscriptionService.subscriptionExpiry;
      _products = _subscriptionService.products;
    } catch (e) {
      debugPrint('Error initializing subscription provider: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Purchase a subscription
  Future<bool> purchaseSubscription(String productId) async {
    _setLoading(true);

    try {
      final success =
          await _subscriptionService.purchaseSubscription(productId);
      return success;
    } catch (e) {
      debugPrint('Error purchasing subscription: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Restore purchases
  Future<bool> restorePurchases() async {
    _setLoading(true);

    try {
      final success = await _subscriptionService.restorePurchases();
      return success;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check if user can add more family members
  bool canAddFamilyMember(int currentCount) {
    return _subscriptionService.canAddFamilyMember(currentCount);
  }

  // Get subscription status text
  String getSubscriptionStatusText() {
    return _subscriptionService.getSubscriptionStatusText();
  }

  // Get monthly subscription product
  ProductDetails? get monthlyProduct {
    try {
      return _products.firstWhere((p) => p.id == 'keepsafe_pro_monthly');
    } catch (e) {
      return null;
    }
  }

  // Get yearly subscription product
  ProductDetails? get yearlyProduct {
    try {
      return _products.firstWhere((p) => p.id == 'keepsafe_pro_yearly');
    } catch (e) {
      return null;
    }
  }

  // Get recommended product (yearly if available, otherwise monthly)
  ProductDetails? get recommendedProduct {
    return yearlyProduct ?? monthlyProduct;
  }

  // Check if products are loaded
  bool get hasProducts => _products.isNotEmpty;

  // Get formatted price for a product
  String getFormattedPrice(ProductDetails product) {
    return product.price;
  }

  // Get savings percentage for yearly vs monthly
  double? getYearlySavings() {
    final monthly = monthlyProduct;
    final yearly = yearlyProduct;

    if (monthly == null || yearly == null) return null;

    try {
      // Extract numeric values from price strings (e.g., "$4.99" -> 4.99)
      final monthlyPrice =
          double.parse(monthly.price.replaceAll(RegExp(r'[^\d.]'), ''));
      final yearlyPrice =
          double.parse(yearly.price.replaceAll(RegExp(r'[^\d.]'), ''));

      final yearlyEquivalent = monthlyPrice * 12;
      final savings =
          ((yearlyEquivalent - yearlyPrice) / yearlyEquivalent) * 100;

      return savings > 0 ? savings : null;
    } catch (e) {
      return null;
    }
  }
}
