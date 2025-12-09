// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../extensions/firestore_extensions.dart';
import 'package:provider/provider.dart';

import '../models/person.dart';
import '../models/purchase.dart';
import 'person_provider.dart';

class PurchasesProvider extends ChangeNotifier {
  List<Purchase>? purchases;

  PurchasesProvider({this.purchases});

  Future<void> fetchPurchases(BuildContext context, {bool? refresh}) async {
    final Person user = context.read<PersonProvider>().user!;

    final purchasesSnapshot = await FirebaseFirestore.instance
        .collection('purchases')
        .where('user_id', isEqualTo: user.uid)
        .orderBy('premium_start_date', descending: true)
        .getSavy(refresh: refresh);
    if (!kReleaseMode) print('fetchPurchases: ${purchasesSnapshot.docs.length}');

    purchases = purchasesSnapshot.docs.map((doc) {
      return Purchase(
        productId: doc['product_id'],
        premiumStartDate: (doc['premium_start_date'] as Timestamp).toDate(),
        premiumEndDate: (doc['premium_end_date'] as Timestamp).toDate(),
        platform: doc['platform'],
        currencySymbol: doc['currency_symbol'],
        rawPrice: doc['raw_price'],
      );
    }).toList();

    notifyListeners();
  }

  Future<List<Object>> getPurchases(BuildContext context) async {
    if (purchases == null) return [];

    return purchases!;
  }

  Future<void> addPurchase(
    BuildContext context,
    String userId,
    PurchaseDetails purchase,
    ProductDetails product,
    DateTime premiumStartDate,
    DateTime premiumEndDate,
    String countryCode,
  ) async {
    await FirebaseFirestore.instance.collection('purchases').add({
      'user_id': userId,
      'product_id': product.id,
      'premium_start_date': premiumStartDate,
      'premium_end_date': premiumEndDate,
      'created_at': FieldValue.serverTimestamp(),
      'platform': Platform.isIOS ? 'iOS' : 'Android',
      'currency_symbol': product.currencySymbol,
      'currency_code': product.currencyCode,
      'price': product.price,
      'raw_price': product.rawPrice.toString(),
      'country_code': countryCode,
    });

    await fetchPurchases(context);
  }
}
