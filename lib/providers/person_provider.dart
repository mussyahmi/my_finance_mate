// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../models/person.dart';

class PersonProvider extends ChangeNotifier {
  Person? user;

  PersonProvider({this.user});

  void setUser({required Person newUser}) async {
    user = newUser;
    notifyListeners();
  }

  Future<void> activateFreeTrial() async {
    DateTime now = DateTime.now();

    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'is_premium': true,
      'premium_start_date': now,
      'premium_end_date': now.add(Duration(days: 7)),
    });

    user!.isPremium = true;
    user!.premiumStartDate = now;
    user!.premiumEndDate = now.add(Duration(days: 7));

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
}
