// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_cycle_page.dart';
import 'add_transaction_page.dart';
import 'settings_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final DateTime _currentDate = DateTime.now();

  String? cycleId;
  String? cycleName;
  String? amountBalance;
  String? amountReceived;
  String? amountSpent;

  @override
  void initState() {
    super.initState();
    //* Call the function when the DashboardPage is loaded
    checkCycleAndShowPopup();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(cycleName ?? 'Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SettingsPage(cycleId: cycleId ?? '')),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to the Dashboard!',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            if (amountBalance != null) Text('Amount Balance: RM$amountBalance'),
            if (amountReceived != null)
              Text('Amount Received: RM$amountReceived'),
            if (amountSpent != null) Text('Amount Spent: RM$amountSpent'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    AddTransactionPage(cycleId: cycleId ?? '')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> checkCycleAndShowPopup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where user is not authenticated
      return;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles');

    final lastCycleQuery =
        cyclesRef.orderBy('cycle_no', descending: true).limit(1);
    final lastCycleSnapshot = await lastCycleQuery.get();

    if (lastCycleSnapshot.docs.isNotEmpty) {
      final lastCycleDoc = lastCycleSnapshot.docs.first;
      final endDateTimestamp = lastCycleDoc['end_date'] as Timestamp;
      final endDate = endDateTimestamp.toDate();

      if (endDate.isBefore(_currentDate)) {
        //* Last cycle has ended, redirect to add cycle page
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const AddCyclePage(isFirstCycle: false)),
        );
      } else {
        //* Get latest cycle
        setState(() {
          cycleId = lastCycleDoc.id;
          cycleName = lastCycleDoc['cycle_name'];
          amountBalance = lastCycleDoc['opening_balance'];
          amountReceived = lastCycleDoc['amount_received'];
          amountSpent = lastCycleDoc['amount_spent'];
        });
      }
    } else {
      //* No cycles found, redirect to add cycle page
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const AddCyclePage(isFirstCycle: true)),
      );
    }
  }
}
