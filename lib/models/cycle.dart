// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../extensions/firestore_extensions.dart';
import '../pages/cycle_add_page.dart';
import '../models/person.dart';

class Cycle {
  String id;
  int cycleNo;
  String cycleName;
  String openingBalance;
  String amountBalance;
  String amountReceived;
  String amountSpent;
  DateTime startDate;
  DateTime endDate;

  Cycle({
    required this.id,
    required this.cycleNo,
    required this.cycleName,
    required this.openingBalance,
    required this.amountBalance,
    required this.amountReceived,
    required this.amountSpent,
    required this.startDate,
    required this.endDate,
  });

  static Future<Cycle?> fetchCycle(BuildContext context, Person user) async {
    final DateTime currentDate = DateTime.now();

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles');

    final cycleQuery = cyclesRef.orderBy('cycle_no', descending: true).limit(1);
    final cycleSnapshot = await cycleQuery.getSavy();
    print('fetchCycle: ${cycleSnapshot.docs.length}');

    if (cycleSnapshot.docs.isNotEmpty) {
      final cycleDoc = cycleSnapshot.docs.first;

      Cycle cycle = Cycle(
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

      if (cycle.endDate.isBefore(currentDate)) {
        //* Last cycle has ended, redirect to add cycle page
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CycleAddPage(
                  user: user, isFirstCycle: false, lastCycle: cycle)),
        );
      }

      return cycle;
    } else {
      //* No cycles found, redirect to add cycle page
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CycleAddPage(user: user, isFirstCycle: true)),
      );

      return null;
    }
  }

  static Future<List<Cycle>> fetchCycles(Person user, [int? limit]) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles');

    var cyclesQuery = cyclesRef
        .where('deleted_at', isNull: true)
        .orderBy('cycle_no', descending: true);

    if (limit != null) {
      cyclesQuery = cyclesQuery.limit(limit);
    }

    final cyclesSnapshot = await cyclesQuery.getSavy();
    print('fetchCycles: ${cyclesSnapshot.docs.length}');

    final cycles = cyclesSnapshot.docs.map((doc) async {
      final data = doc.data();

      //* Create a Transaction object with the category name
      return Cycle(
        id: doc.id,
        cycleNo: data['cycle_no'],
        cycleName: data['cycle_name'],
        openingBalance: data['opening_balance'],
        amountBalance: data['amount_balance'],
        amountReceived: data['amount_received'],
        amountSpent: data['amount_spent'],
        startDate: (data['start_date'] as Timestamp).toDate(),
        endDate: (data['end_date'] as Timestamp).toDate(),
      );
    }).toList();

    var result = await Future.wait(cycles);

    return result;
  }
}
