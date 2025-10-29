// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../extensions/firestore_extensions.dart';
import '../models/person.dart';
import '../models/debt.dart';
import 'person_provider.dart';

class DebtProvider with ChangeNotifier {
  List<Debt>? debts = [];

  DebtProvider({this.debts});

  Future<void> fetchDebts(BuildContext context, {bool? refresh}) async {
    final Person user = context.read<PersonProvider>().user!;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('debts')
        .where('deleted_at', isNull: true)
        .getSavy(refresh: refresh);

    print('fetchDebts: ${snapshot.docs.length}');

    debts =
        snapshot.docs.map((doc) => Debt.fromMap(doc.id, doc.data())).toList();

    debts!.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    notifyListeners();
  }

  Future<List<Debt>> getUnsettledDebts(BuildContext context) async {
    if (debts == null) return [];
    return debts!.where((debt) => !debt.isSettled).toList();
  }

  Future<List<Debt>> getSettledDebts(BuildContext context) async {
    if (debts == null) return [];
    return debts!.where((debt) => debt.isSettled).toList();
  }

  Future<void> updateDebt(BuildContext context, String action,
      String personName, String amount, DebtType type, String note,
      {Debt? debt}) async {
    final Person user = context.read<PersonProvider>().user!;

    //* Get current timestamp
    final now = DateTime.now();

    if (action == 'Add') {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('debts')
          .doc();

      await docRef.set({
        "personName": personName,
        "amount": amount,
        "type": type == DebtType.iOwe ? "iOwe" : "theyOweMe",
        "note": note,
        "createdAt": now,
        "updated_at": now,
        'deleted_at': null,
      });
    } else if (action == 'Edit') {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('debts')
          .doc(debt!.id)
          .update({
        'personName': personName,
        'amount': amount,
        'type': type == DebtType.iOwe ? 'iOwe' : 'theyOweMe',
        'note': note,
        "updated_at": now,
      });
    }

    await fetchDebts(context);
  }

  Future<void> toggleSettleDebt(BuildContext context, Debt debt) async {
    final Person user = context.read<PersonProvider>().user!;

    //* Get current timestamp
    final now = DateTime.now();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('debts')
        .doc(debt.id)
        .update({
      'isSettled': !debt.isSettled,
      'updated_at': now,
    });

    await fetchDebts(context);
  }

  Future<void> deleteDebt(BuildContext context, Debt debt) async {
    final Person user = context.read<PersonProvider>().user!;

    //* Get current timestamp
    final now = DateTime.now();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('debts')
        .doc(debt.id)
        .update({
      'updated_at': now,
      'deleted_at': now,
    });

    await fetchDebts(context);
  }
}
