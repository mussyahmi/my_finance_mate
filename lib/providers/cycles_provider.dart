// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../extensions/firestore_extensions.dart';
import '../models/cycle.dart';
import '../models/person.dart';
import 'user_provider.dart';

class CyclesProvider extends ChangeNotifier {
  List<Cycle>? cycles;

  CyclesProvider({this.cycles});

  Future<void> fetchCycles(BuildContext context, {bool? refresh}) async {
    final Person user = context.read<UserProvider>().user!;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles');

    final cyclesSnapshot = await cyclesRef
        .orderBy('cycle_no', descending: true)
        .getSavy(refresh: refresh);
    print('fetchCycles: ${cyclesSnapshot.docs.length}');

    final futureCycles = cyclesSnapshot.docs.map((doc) async {
      final data = doc.data();

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

    cycles = await Future.wait(futureCycles);
    notifyListeners();
  }

  Future<List<Cycle>> getLatestCycles() async {
    if (cycles == null) return [];

    return cycles!.take(5).toList();
  }
}
