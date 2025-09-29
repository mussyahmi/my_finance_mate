// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import '../models/person.dart';
// import '../services/purchase_service.dart';
import '../pages/dashboard_page.dart';
import 'accounts_provider.dart';
import 'categories_provider.dart';
import 'cycle_provider.dart';
import 'debt_provider.dart';
import 'purchases_provider.dart';
import 'qada_prayer_provider.dart';
import 'transactions_provider.dart';
import 'wishlist_provider.dart';

class PersonProvider extends ChangeNotifier {
  Person? user;

  PersonProvider({this.user});

  void setUser({required Person newUser}) async {
    user = newUser;
    notifyListeners();
  }

  bool isEmulator() {
    final deviceInfoMap = jsonDecode(user!.deviceInfoJson);
    return !deviceInfoMap['isPhysicalDevice'];
  }

  Future<void> activateFreeTrial() async {
    final DateTime now = DateTime.now();
    final Duration subscriptionDuration = Duration(days: 7);

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'is_premium': true,
      'premium_start_date': now,
      'premium_end_date': now.add(subscriptionDuration),
    });

    user!.isPremium = true;
    user!.premiumStartDate = now;
    user!.premiumEndDate = now.add(subscriptionDuration);

    notifyListeners();
  }

  Future<void> activatePremium(
    BuildContext context,
    PurchaseDetails purchase,
    ProductDetails product,
    String countryCode,
  ) async {
    DateTime premiumStartDate = DateTime.fromMillisecondsSinceEpoch(
        int.parse(purchase.transactionDate!));
    Duration subscriptionDuration;

    switch (product.id) {
      case '1_day_access':
        subscriptionDuration = Duration(days: 1);
        break;
      case '1_week_access':
        subscriptionDuration = Duration(days: 7);
        break;
      case 'monthly_access':
        if (isEmulator()) {
          subscriptionDuration = Duration(minutes: 5);
        } else {
          subscriptionDuration = Duration(days: 30); // TODO: need to confirm
        }
        break;
      case 'yearly_access':
        if (isEmulator()) {
          subscriptionDuration = Duration(minutes: 30);
        } else {
          subscriptionDuration = Duration(days: 365); // TODO: need to confirm
        }
        break;
      default:
        print("Unknown product ID: ${product.id}");
        return;
    }

    DateTime now = DateTime.now();

    if (isEmulator()) {
      int minutesPassed = now.difference(premiumStartDate).inMinutes;
      int subscriptionCount =
          (minutesPassed / subscriptionDuration.inMinutes).floor();
      premiumStartDate = premiumStartDate.add(
        Duration(minutes: subscriptionCount * subscriptionDuration.inMinutes),
      );
    } else {
      int daysPassed = now.difference(premiumStartDate).inDays;
      int subscriptionCount =
          (daysPassed / subscriptionDuration.inMinutes).floor();
      premiumStartDate = premiumStartDate.add(
        Duration(minutes: subscriptionCount * subscriptionDuration.inDays),
      );
    }

    DateTime premiumEndDate = premiumStartDate.add(subscriptionDuration);

    print('Activating premium access: $premiumStartDate to $premiumEndDate');

    // 🔥 Update user premium status
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'is_premium': true,
      'premium_start_date': premiumStartDate,
      'premium_end_date': premiumEndDate,
    });

    // ✅ Save to purchase history
    await context.read<PurchasesProvider>().addPurchase(
          context,
          user!.uid,
          purchase,
          product,
          premiumStartDate,
          premiumEndDate,
          countryCode,
        );

    user!.isPremium = true;
    user!.premiumStartDate = premiumStartDate;
    user!.premiumEndDate = premiumEndDate;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('show_premium_ended', false);

    notifyListeners();

    EasyLoading.dismiss();

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Purchase Successful'),
            content: Text(
                'Enjoy your premium access! Your Premium access is active until ${DateFormat('EEEE, d MMMM yyyy h:mm aa').format(premiumEndDate)}'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        });
  }

  Future<void> endPremiumAccess() async {
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'is_premium': false,
    });

    user!.isPremium = false;

    notifyListeners();
  }

  Future<void> checkTransactionMade(DateTime lastTransactionDate) async {
    DateTime now = DateTime.now();

    if (!(lastTransactionDate.year == now.year &&
            lastTransactionDate.month == now.month &&
            lastTransactionDate.day == now.day) &&
        lastTransactionDate.isBefore(now) &&
        user!.dailyTransactionsMade > 0) {
      await resetTransactionMade();
    }
  }

  Future<void> resetTransactionMade() async {
    //* Update transactions made
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({'daily_transactions_made': 0});

    user!.dailyTransactionsMade = 0;
    notifyListeners();
  }

  Future<void> updateDisplayName(String displayName) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({'display_name': displayName});

    user!.displayName = displayName;

    notifyListeners();
  }

  Future<void> uploadProfileImage(file) async {
    //* Generate a unique file name
    String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';

    Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('${user!.uid}/profile_image/$fileName');

    UploadTask uploadTask = storageReference.putFile(File(file.path!));

    await uploadTask.whenComplete(() async {
      print('File Uploaded');
      String downloadURL = await storageReference.getDownloadURL();
      print('Download URL: $downloadURL');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'image_url': downloadURL});

      user!.imageUrl = downloadURL;
    });

    notifyListeners();
  }

  Future<void> changePassword(
    BuildContext context,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      //* Re-authenticate the user with their current password
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(credential);

        //* Update the password
        await user.updatePassword(newPassword);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'password': newPassword});

        EasyLoading.showSuccess('Password changed successfully');

        Navigator.of(context).pop(true);
      } else {
        EasyLoading.showError('User not authenticated.');
      }
    } catch (e) {
      EasyLoading.showError('Failed to change password. Error: $e');
    }
  }

  Future<void> resetForceRefresh() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .update({'force_refresh': false});

    user!.forceRefresh = false;

    notifyListeners();
  }

  Future<void> fetchData(BuildContext context) async {
    final bool forceRefresh = user!.forceRefresh;

    await context
        .read<CycleProvider>()
        .fetchCycle(context, refresh: forceRefresh);

    await context.read<CategoriesProvider>().fetchCategories(
        context, context.read<CycleProvider>().cycle!,
        refresh: forceRefresh);

    await context.read<AccountsProvider>().fetchAccounts(
        context, context.read<CycleProvider>().cycle!,
        refresh: forceRefresh);

    await context.read<TransactionsProvider>().fetchTransactions(
        context, context.read<CycleProvider>().cycle!,
        refresh: forceRefresh);

    await context
        .read<WishlistProvider>()
        .fetchWishlist(context, refresh: forceRefresh);

    await context
        .read<DebtProvider>()
        .fetchDebts(context, refresh: forceRefresh);

    await context
        .read<QadaPrayerProvider>()
        .fetchQadaPrayers(context, refresh: forceRefresh);

    await context
        .read<PurchasesProvider>()
        .fetchPurchases(context, refresh: forceRefresh);

    await checkAndUpdatePremiumStatus(context);

    if (forceRefresh) await resetForceRefresh();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => ShowCaseWidget(
          builder: (context) => const DashboardPage(),
          globalFloatingActionWidget: (showcaseContext) => FloatingActionWidget(
            right: 16,
            top: 16,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: ShowCaseWidget.of(showcaseContext).dismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: Text(
                  'Skip Tour',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      (route) => false, //* This line removes all previous routes from the stack
    );
  }

  Future<void> checkAndUpdatePremiumStatus(BuildContext context) async {
    if (user!.premiumEndDate != null &&
        user!.premiumEndDate!.isBefore(DateTime.now())) {
      await endPremiumAccess();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_premium_ended', true);

      // final PurchaseService purchaseService = PurchaseService();
      // await purchaseService.initialize(context);
      // await InAppPurchase.instance.restorePurchases();
    }
  }
}
