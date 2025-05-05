// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/person.dart';
import 'accounts_provider.dart';
import 'categories_provider.dart';
import 'cycle_provider.dart';
import 'cycles_provider.dart';
import 'transactions_provider.dart';
import 'wishlist_provider.dart';

class PersonProvider extends ChangeNotifier {
  Person? user;

  PersonProvider({this.user});

  void setUser({required Person newUser}) async {
    user = newUser;
    notifyListeners();
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

  Future<void> activatePremium(String productId, String transactionDate) async {
    final DateTime transactionDateTime =
        DateTime.fromMillisecondsSinceEpoch(int.parse(transactionDate));
    Duration subscriptionDuration;

    //* Set subscription duration based on the product ID
    switch (productId) {
      case 'one_day_access':
        subscriptionDuration = Duration(days: 1);
        break;
      case 'one_week_access':
        subscriptionDuration = Duration(days: 7);
        break;
      case 'monthly_access':
        subscriptionDuration = Duration(days: 30);
        break;
      case 'yearly_access':
        subscriptionDuration = Duration(days: 365);
        break;
      default:
        print("Unknown product ID: $productId");
        return;
    }

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'is_premium': true,
      'premium_start_date': transactionDateTime,
      'premium_end_date': transactionDateTime.add(subscriptionDuration),
    });

    user!.isPremium = true;
    user!.premiumStartDate = transactionDateTime;
    user!.premiumEndDate = transactionDateTime.add(subscriptionDuration);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('show_premium_ended', false);

    notifyListeners();
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

    await context
        .read<CyclesProvider>()
        .fetchCycles(context, refresh: forceRefresh);

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

    if (forceRefresh) await resetForceRefresh();
  }
}
