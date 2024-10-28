import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/person.dart';

class UserProvider extends ChangeNotifier {
  Person? user;

  UserProvider({this.user});

  void setUser({required Person newUser}) async {
    user = newUser;
    notifyListeners();
  }

  Future<void> checkTransactionMade(DateTime lastTansactionDate) async {
    DateTime today = DateTime.now();

    if (!(lastTansactionDate.year == today.year &&
            lastTansactionDate.month == today.month &&
            lastTansactionDate.day == today.day) &&
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
}
