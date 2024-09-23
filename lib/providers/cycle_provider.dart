// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../extensions/firestore_extensions.dart';
import '../models/cycle.dart';
import '../models/person.dart';
import '../models/transaction.dart' as t;
import '../pages/cycle_add_page.dart';
import '../pages/dashboard_page.dart';
import 'user_provider.dart';

class CycleProvider extends ChangeNotifier {
  Cycle? cycle;

  CycleProvider({this.cycle});

  Future<void> fetchCycle(BuildContext context, {bool? refresh}) async {
    final Person user = context.read<UserProvider>().user!;
    final DateTime now = DateTime.now();

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles');

    final cycleQuery = cyclesRef.orderBy('cycle_no', descending: true).limit(1);
    final cycleSnapshot = await cycleQuery.getSavy(refresh: refresh);
    print('fetchCycle: ${cycleSnapshot.docs.length}');

    if (cycleSnapshot.docs.isNotEmpty) {
      final cycleDoc = cycleSnapshot.docs.first;

      cycle = Cycle(
        id: cycleDoc.id,
        cycleNo: cycleDoc['cycle_no'],
        cycleName: cycleDoc['cycle_name'],
        openingBalance: cycleDoc['opening_balance'],
        amountBalance: cycleDoc['amount_balance'],
        amountReceived: cycleDoc['amount_received'],
        amountSpent: cycleDoc['amount_spent'],
        startDate: (cycleDoc['start_date'] as Timestamp).toDate(),
        endDate: (cycleDoc['end_date'] as Timestamp).toDate(),
      );

      if (cycle!.endDate.isBefore(now)) {
        //* Last cycle has ended, redirect to add cycle page
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CycleAddPage()),
        );
      }

      notifyListeners();
    } else {
      //* No cycles found, redirect to add cycle page
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CycleAddPage()),
      );
    }
  }

  Future<void> addCycle(BuildContext context, String cycleName,
      DateTime startDate, DateTime endDate, String openingBalance) async {
    final Person user = context.read<UserProvider>().user!;
    final DateTime now = DateTime.now();

    //* Create the new cycle document
    final newCycleDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycles')
        .add({
      'cycle_no': cycle != null ? cycle!.cycleNo + 1 : 1,
      'cycle_name': cycleName,
      'start_date': startDate,
      'end_date': endDate,
      'created_at': now,
      'updated_at': now,
      'deleted_at': null,
      'opening_balance': openingBalance,
      'amount_balance': openingBalance,
      'amount_received': '0.00',
      'amount_spent': '0.00',
    });

    if (cycle != null) {
      await _copyCategoriesFromLastCycle(user, cycle!.id, newCycleDoc.id);
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DashboardPage()),
      (route) => false, //* This line removes all previous routes from the stack
    );
  }

  Future<void> _copyCategoriesFromLastCycle(
      Person user, String lastCycleId, String newCycleId) async {
    final categoriesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycles')
        .doc(lastCycleId)
        .collection('categories');

    final newCycleRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycles')
        .doc(newCycleId);

    final categoriesSnapshot =
        await categoriesRef.where('deleted_at', isNull: true).getSavy();
    print('copyCategoriesFromLastCycle: ${categoriesSnapshot.docs.length}');

    for (var doc in categoriesSnapshot.docs) {
      final categoryData = doc.data();
      categoryData['total_amount'] = '0.00'; //* Set total_amount to '0.00'
      await newCycleRef.collection('categories').add(categoryData);
    }
  }

  Future<void> updateCycleByAttribute(
    BuildContext context,
    String attribute,
    dynamic value,
  ) async {
    final Person user = context.read<UserProvider>().user!;
    final Cycle cycle = context.read<CycleProvider>().cycle!;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cycles')
        .doc(cycle.id)
        .update({attribute: value});

    if (attribute == 'cycle_name') {
      cycle.cycleName = value;
    } else if (attribute == 'end_date') {
      cycle.endDate = value;
    }

    notifyListeners();
  }

  Future<void> updateCycleFromTransaction(
    BuildContext context,
    String action,
    String type,
    String amount,
    DateTime now,
    t.Transaction? transaction,
  ) async {
    final Person user = context.read<UserProvider>().user!;
    final Cycle cycle = context.read<CycleProvider>().cycle!;

    final double cycleOpeningBalance = double.parse(cycle.openingBalance);
    double cycleAmountReceived = double.parse(cycle.amountReceived);
    double cycleAmountSpent = double.parse(cycle.amountSpent);

    //* Calculate the cycle's amounts before including this transaction
    if (action == 'Edit' || action == 'Delete') {
      if (type == 'spent') {
        cycleAmountSpent -= double.parse(transaction!.amount);
      } else {
        cycleAmountReceived -= double.parse(transaction!.amount);
      }
    }

    final newAmount = double.parse(amount);

    double updatedAmountBalance =
        cycleOpeningBalance + cycleAmountReceived - cycleAmountSpent;

    if (action != 'Delete') {
      updatedAmountBalance += type == 'spent' ? -newAmount : newAmount;
      cycleAmountSpent += type == 'spent' ? newAmount : 0;
      cycleAmountReceived += type == 'received' ? newAmount : 0;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles');

    //* Update the cycle document
    await cyclesRef.doc(cycle.id).update({
      'amount_spent': cycleAmountSpent.toStringAsFixed(2),
      'amount_received': cycleAmountReceived.toStringAsFixed(2),
      'amount_balance': updatedAmountBalance.toStringAsFixed(2),
      'updated_at': now,
    });
  }
}
