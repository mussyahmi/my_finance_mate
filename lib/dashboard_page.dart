// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:my_finance_mate/size_config.dart';

import 'add_cycle_page.dart';
import 'transaction_form_page.dart';
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
    _checkCycleAndShowPopup();
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

    final transactionQuery =
        await transactionsRef.where('deleted_at', isNull: true).get();
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

      //* Create a Transaction object with the category name
      return t.Transaction(
        id: doc.id,
        cycleId: data['cycleId'],
        dateTime: (data['dateTime'] as Timestamp).toDate(),
        type: data['type'] as String,
        categoryId: data['categoryId'],
        categoryName: categoryName,
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
    //* Initialize SizeConfig
    SizeConfig().init(context);

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Card(
                elevation: 3,
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Amount Balance',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RM $amountBalance',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Card(
                      elevation: 3,
                      margin: const EdgeInsets.fromLTRB(16, 0, 8, 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Amount Received',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'RM $amountReceived',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      elevation: 3,
                      margin: const EdgeInsets.fromLTRB(8, 0, 16, 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Amount Spent',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'RM $amountSpent',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: CircularProgressIndicator(),
                    ); //* Display a loading indicator
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'Error: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'No transactions found.',
                        textAlign: TextAlign.center,
                      ),
                    ); //* Display a message for no transactions
                  } else {
                    //* Display the list of transactions
                    final transactions = snapshot.data;
                    return Container(
                      constraints: BoxConstraints.loose(
                          Size(SizeConfig.screenWidth!, 300)),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: transactions!.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return Dismissible(
                            key: Key(transaction
                                .id), //* Unique key for each transaction
                            background: Container(
                              color: Colors
                                  .green, //* Background color for edit action
                              alignment: Alignment.centerLeft,
                              child: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            secondaryBackground: Container(
                              color: Colors
                                  .red, //* Background color for delete action
                              alignment: Alignment.centerRight,
                              child: const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                //* Edit action
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TransactionFormPage(
                                      cycleId: cycleId ?? '',
                                      action: 'Edit',
                                      transaction: transaction,
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  _checkCycleAndShowPopup();
                                  _fetchTransactions();
                                  return true;
                                } else {
                                  return false;
                                }
                              } else if (direction ==
                                  DismissDirection.endToStart) {
                                //* Delete action
                                return await _deleteTransaction(transaction);
                              }

                              return false;
                            },
                            child: ListTile(
                              title: Text(
                                transaction.categoryName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Text(
                                DateFormat('EE, d MMM yyyy h:mm aa')
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
                              onTap: () {
                                //* Show the transaction summary dialog when tapped
                                _showTransactionSummaryDialog(transaction);
                              },
                            ),
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
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TransactionFormPage(cycleId: cycleId ?? '', action: 'Add'),
            ),
          );

          if (result == true) {
            _checkCycleAndShowPopup();
            _fetchTransactions();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _checkCycleAndShowPopup() async {
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
          amountBalance = lastCycleDoc['amount_balance'];
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

  void _showTransactionSummaryDialog(t.Transaction transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Transaction Summary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Category:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(transaction.categoryName),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Date:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    DateFormat('EE, d MMM yyyy\nh:mm aa')
                        .format(transaction.dateTime),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amount:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('RM${transaction.amount}'),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Type:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                      '${transaction.type[0].toUpperCase()}${transaction.type.substring(1)}'),
                ],
              ),
              if (transaction.note.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Note:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(transaction.note.replaceAll('\\n', '\n')),
                  ],
                ),
              //* Add more transaction details as needed
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); //* Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _deleteTransaction(t.Transaction transaction) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content:
              const Text('Are you sure you want to delete this transaction?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); //* Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                //* Delete the item from Firestore here
                final transactionId = transaction.id;

                //* Reference to the Firestore document to delete
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  //todo: Handle the case where the user is not authenticated
                  return;
                }

                final userRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid);
                final transactionRef =
                    userRef.collection('transactions').doc(transactionId);

                //* Update the 'deleted_at' field with the current timestamp
                final now = DateTime.now();
                transactionRef.update({'deleted_at': now});

                final cyclesRef = userRef.collection('cycles').doc(cycleId);

                //* Fetch the current cycle document
                final cycleDoc = await cyclesRef.get();

                if (cycleDoc.exists) {
                  final cycleData = cycleDoc.data() as Map<String, dynamic>;

                  //* Calculate the updated amounts
                  final double cycleOpeningBalance =
                      double.parse(cycleData['opening_balance']);
                  final double cycleAmountReceived =
                      double.parse(cycleData['amount_received']) +
                          (transaction.type == 'received'
                              ? -double.parse(transaction.amount)
                              : 0);
                  final double cycleAmountSpent =
                      double.parse(cycleData['amount_spent']) +
                          (transaction.type == 'spent'
                              ? -double.parse(transaction.amount)
                              : 0);

                  final double updatedAmountBalance = cycleOpeningBalance +
                      cycleAmountReceived -
                      cycleAmountSpent;

                  //* Update the cycle document
                  await cyclesRef.update({
                    'amount_spent': cycleAmountSpent.toStringAsFixed(2),
                    'amount_received': cycleAmountReceived.toStringAsFixed(2),
                    'amount_balance': updatedAmountBalance.toStringAsFixed(2),
                  });
                }

                _checkCycleAndShowPopup();
                _fetchTransactions();

                Navigator.of(context).pop(true); //* Close the dialog
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
