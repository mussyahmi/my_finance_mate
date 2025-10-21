// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../providers/person_provider.dart';

class PurchaseService {
  PurchaseService._privateConstructor();

  static final PurchaseService _instance =
      PurchaseService._privateConstructor();

  factory PurchaseService() => _instance;

  final InAppPurchase _iap = InAppPurchase.instance;
  final Set<String> _productIds = {
    '1_day_access',
    '1_week_access',
    '1_month_access',
    '1_year_access',
    'monthly_access',
    'yearly_access'
  };

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  BuildContext? _context;
  bool _isAvailable = false;
  List<ProductDetails> _products = [];

  Future<void> initialize(BuildContext context) async {
    _context = context;
    _isAvailable = await _iap.isAvailable();
    if (_isAvailable) {
      await _fetchProducts();
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () {
          _subscription?.cancel();
        },
        onError: (error) {
          print("Purchase Error: $error");
        },
      );
    }
  }

  Future<void> _fetchProducts() async {
    final ProductDetailsResponse response =
        await _iap.queryProductDetails(_productIds.toSet());
    if (response.error == null) {
      _products = response.productDetails;
    } else {
      print("Error fetching products: ${response.error}");
    }
  }

  List<ProductDetails> get products => _products;

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final bool valid = await _verifyPurchase(purchase);
        if (valid) {
          _deliverProduct(purchase);
        } else {
          _handleInvalidPurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.pending) {
        EasyLoading.show(
          dismissOnTap: false,
          status: "Processing purchase... Please wait.",
        );
      } else if (purchase.status == PurchaseStatus.error) {
        _handlePurchaseError(purchase.error);
      } else if (purchase.status == PurchaseStatus.canceled) {
        EasyLoading.showInfo("Purchase canceled.");
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // TODO: Implement your own purchase verification here.
    return true;
  }

  void _deliverProduct(PurchaseDetails purchase) async {
    final matchedProduct = _products.firstWhere(
      (product) => product.id == purchase.productID,
      orElse: () => throw Exception("Product not found"),
    );

    String countryCode = await _iap.countryCode();

    EasyLoading.show(
      dismissOnTap: false,
      status: "Activating premium access...",
    );

    await _context!.read<PersonProvider>().activatePremium(
          _context!,
          purchase,
          matchedProduct,
          countryCode,
        );
  }

  void _handleInvalidPurchase(PurchaseDetails purchase) {
    EasyLoading.showError("Invalid purchase! Please try again.");
  }

  void _handlePurchaseError(IAPError? error) {
    EasyLoading.showError(
        "Purchase error: ${error?.message}. Please try again.");
  }

  void dispose() {
    _subscription?.cancel();
  }
}
