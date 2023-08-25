// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'add_cycle_page.dart';
import 'add_transaction_page.dart';
import 'settings_page.dart';
import 'transaction.dart' as t;

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

  Future<List<t.Transaction>> _fetchTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where the user is not authenticated.
      return [];
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final transactionsRef = userRef.collection('transactions');

    final transactionQuery = await transactionsRef.get();
    final transactions = transactionQuery.docs.map((doc) async {
      final data = doc.data();

      //* Fetch the category name based on the categoryId
      final categoryDoc = await userRef
          .collection('cycles')
          .doc(data['cycleId'])
          .collection('categories')
          .doc(data['categoryId'])
          .get();

      final categoryName = categoryDoc['name'] as String;

      //* Fetch the subcategory name based on the subcategoryId
      final subcategoryDoc = await userRef
          .collection('cycles')
          .doc(data['cycleId'])
          .collection('categories')
          .doc(data['categoryId'])
          .collection('subcategories')
          .doc(data['subcategoryId'])
          .get();

      final subcategoryName = subcategoryDoc['name'] as String;

      //* Create a Transaction object with the category name
      return t.Transaction(
        id: doc.id,
        cycleId: data['cycleId'],
        dateTime: (data['dateTime'] as Timestamp).toDate(),
        type: data['type'] as String,
        categoryId: data['categoryId'],
        categoryName: categoryName,
        subcategoryId: data['subcategoryId'],
        subcategoryName: subcategoryName,
        amount: data['amount'] as String,
        note: data['note'] as String,
        //* Add other transaction properties as needed
      );
    }).toList();

    var result = await Future.wait(transactions);

    //* Sort the list by 'created_at' in ascending order (most recent first)
    result.sort((a, b) => (b.dateTime).compareTo(a.dateTime));

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Text(
                'Amount Balance: RM$amountBalance',
                textAlign: TextAlign.center,
              ),
              Text(
                'Amount Received: RM$amountReceived',
                textAlign: TextAlign.center,
              ),
              Text(
                'Amount Spent: RM$amountSpent',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transaction List',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    TextButton(onPressed: () {}, child: const Text('View All'))
                  ],
                ),
              ),
              FutureBuilder<List<t.Transaction>>(
                future: _fetchTransactions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(); //* Display a loading indicator
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text(
                        'No transactions found.'); //* Display a message for no transactions
                  } else {
                    //* Display the list of transactions
                    final transactions = snapshot.data;
                    return SizedBox(
                      height: 300,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: transactions!.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return ListTile(
                            title: Row(
                              children: [
                                Text(
                                  transaction.subcategoryName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  child: Text(
                                    transaction.categoryName,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              DateFormat('EE, dd MMM yyyy hh:mm aa')
                                  .format(transaction.dateTime),
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              '${transaction.type == 'spent' ? '-' : ''}RM${transaction.amount}',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: transaction.type == 'spent'
                                      ? Colors.red
                                      : Colors.green),
                            ),
                            onTap: () {},
                          );
                        },
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTransactionPage(cycleId: cycleId ?? ''),
            ),
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
