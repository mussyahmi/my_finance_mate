import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dashboard_page.dart';

class AddCyclePage extends StatefulWidget {
  final bool isFirstCycle;

  const AddCyclePage({super.key, required this.isFirstCycle});

  @override
  AddCyclePageState createState() => AddCyclePageState();
}

class AddCyclePageState extends State<AddCyclePage> {
  TextEditingController cycleNameController = TextEditingController();
  TextEditingController openingBalanceController = TextEditingController();
  DateTimeRange? selectedDateRange;

  String? lastCycleBalance;
  int lastCycleNo = 0;

  @override
  void initState() {
    super.initState();
    if (!widget.isFirstCycle) {
      //* Fetch the last cycle's balance and number if it's not the first cycle
      fetchLastCycleData();
    }
  }

  Future<void> fetchLastCycleData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where the user is not authenticated
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
      setState(() {
        lastCycleBalance =
            openingBalanceController.text = lastCycleDoc['amount_balance'];
        lastCycleNo = lastCycleDoc['cycle_no'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        //* Prevent the user from navigating back using the back button
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create New Cycle'),
          centerTitle: true,
          automaticallyImplyLeading: false, //* Hide the back icon button
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final pickedDateRange = await showDateRangePicker(
                      context: context,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );

                    if (pickedDateRange != null) {
                      setState(() {
                        selectedDateRange = pickedDateRange;
                      });
                    }
                  },
                  child: Text(
                    selectedDateRange != null
                        ? 'Date Range:\n${DateFormat('EE, d MMM yyyy').format(selectedDateRange!.start)} - ${DateFormat('EE, d MMM yyyy').format(selectedDateRange!.end)}'
                        : 'Select Date Range',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cycleNameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: openingBalanceController,
                  keyboardType:
                      TextInputType.number, //* Allow only numeric input
                  decoration: InputDecoration(
                    labelText:
                        '${widget.isFirstCycle ? 'Opening' : 'Previous'} Balance',
                    prefixText: 'RM ',
                  ),
                  enabled: widget.isFirstCycle,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    //todo: validation
                    //todo: selectedDateRange must have today's date
                    //todo: cycle's name is required
                    //todo: opening balance, should be able to enter number only, and will automatically assign decimal point

                    if (selectedDateRange != null) {
                      final adjustedEndDate = selectedDateRange!.end
                          .add(const Duration(days: 1))
                          .subtract(const Duration(minutes: 1));

                      //* Get the current user
                      final user = FirebaseAuth.instance.currentUser;

                      if (user == null) {
                        //todo: Handle the case where user is not authenticated
                        return;
                      }

                      //* Get current timestamp
                      final now = DateTime.now();

                      //* Create the new cycle document
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('cycles')
                          .add({
                        'cycle_no': lastCycleNo + 1,
                        'cycle_name': cycleNameController.text,
                        'start_date': selectedDateRange!.start,
                        'end_date': adjustedEndDate,
                        'created_at': now,
                        'updated_at': now,
                        'deleted_at': null,
                        'opening_balance':
                            double.parse(openingBalanceController.text)
                                .toStringAsFixed(2),
                        'amount_balance':
                            double.parse(openingBalanceController.text)
                                .toStringAsFixed(2),
                        'amount_received': '0.00',
                        'amount_spent': '0.00',
                      });

                      // ignore: use_build_context_synchronously
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DashboardPage()),
                        (route) =>
                            false, //* This line removes all previous routes from the stack
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
