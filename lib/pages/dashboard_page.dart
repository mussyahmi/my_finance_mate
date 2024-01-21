// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../size_config.dart';
import '../widgets/forecast_budget.dart';
import 'add_cycle_page.dart';
import 'transaction_form_page.dart';
import 'settings_page.dart';
import '../models/transaction.dart' as t;
import 'transaction_list_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late SharedPreferences prefs;
  String? cycleId;
  String? cycleName;
  String? amountBalance;
  String? amountReceived;
  String? amountSpent;
  String? openingBalance;
  bool _isAmountVisible = false;

  @override
  void initState() {
    super.initState();
    //* Call the function when the DashboardPage is loaded
    _refreshPage();
  }

  Future<void> _refreshPage() async {
    await _fetchCycle();
    setState(() {});
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
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SettingsPage(cycleId: cycleId ?? '')),
              );

              SharedPreferences prefs = await SharedPreferences.getInstance();
              if (prefs.getBool('refresh_dashboard') ?? false) {
                await prefs.remove('refresh_dashboard');
                await _refreshPage();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPage,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isAmountVisible = !_isAmountVisible;
                  });
                },
                child: Card(
                  elevation: 3,
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Available Balance',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          !_isAmountVisible ? 'RM ****' : 'RM $amountBalance',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Opening Balance: ${!_isAmountVisible ? 'RM ****' : 'RM $openingBalance'}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransactionListPage(
                              cycleId: cycleId ?? '',
                              type: 'received',
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 3,
                        margin: const EdgeInsets.fromLTRB(16, 0, 8, 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Received',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                !_isAmountVisible
                                    ? 'RM ****'
                                    : 'RM $amountReceived',
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
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransactionListPage(
                              cycleId: cycleId ?? '',
                              type: 'spent',
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 3,
                        margin: const EdgeInsets.fromLTRB(8, 0, 16, 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Spent',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                !_isAmountVisible
                                    ? 'RM ****'
                                    : 'RM $amountSpent',
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
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ForecastBudget(
                cycleId: cycleId ?? '',
                amountBalance: amountBalance ?? '0.00',
              ),
              const SizedBox(height: 20),
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
                    TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  TransactionListPage(cycleId: cycleId ?? ''),
                            ),
                          );
                        },
                        child: const Text('View All'))
                  ],
                ),
              ),
              FutureBuilder<List<t.Transaction>>(
                future: _fetchTransactions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                        ],
                      ),
                    ); //* Display a loading indicator
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: SelectableText(
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
                                      cycleId: transaction.cycleId,
                                      action: 'Edit',
                                      transaction: transaction,
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  await _refreshPage();
                                  return true;
                                } else {
                                  return false;
                                }
                              } else if (direction ==
                                  DismissDirection.endToStart) {
                                //* Delete action
                                final result = await transaction
                                    .deleteTransaction(context);

                                if (result == true) {
                                  await _refreshPage();
                                  return true;
                                } else {
                                  return false;
                                }
                              }

                              return false;
                            },
                            child: ListTile(
                              title: Text(
                                transaction.categoryName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('EE, d MMM yyyy h:mm aa')
                                        .format(transaction.dateTime),
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    transaction.note.split('\\n')[0],
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey),
                                  ),
                                ],
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
                                transaction
                                    .showTransactionSummaryDialog(context);
                              },
                            ),
                          );
                        },
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TransactionFormPage(cycleId: cycleId ?? '', action: 'Add'),
            ),
          );

          if (result == true) {
            await _refreshPage();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Transaction'),
      ),
    );
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

    final transactionQuery = await transactionsRef
        .where('deleted_at', isNull: true)
        .orderBy('date_time',
            descending: true) //* Sort by dateTime in descending order
        .limit(10) //* Limit to 10 items
        .get();
    final transactions = transactionQuery.docs.map((doc) async {
      final data = doc.data();

      //* Fetch the category name based on the categoryId
      DocumentSnapshot<Map<String, dynamic>> categoryDoc;
      categoryDoc = await userRef
          .collection('cycles')
          .doc(data['cycle_id'])
          .collection('categories')
          .doc(data['category_id'])
          .get();

      final categoryName = categoryDoc['name'] as String;

      //* Create a Transaction object with the category name
      return t.Transaction(
        id: doc.id,
        cycleId: data['cycle_id'],
        dateTime: (data['date_time'] as Timestamp).toDate(),
        type: data['type'] as String,
        categoryId: data['category_id'],
        categoryName: categoryName,
        amount: data['amount'] as String,
        note: data['note'] as String,
        files: data['files'] != null ? data['files'] as List : [],
        //* Add other transaction properties as needed
      );
    }).toList();

    var result = await Future.wait(transactions);

    //* Sort the list by 'created_at' in ascending order (most recent first)
    result.sort((a, b) => (b.dateTime).compareTo(a.dateTime));

    return result;
  }

  Future<void> _fetchCycle() async {
    final DateTime currentDate = DateTime.now();

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

      if (endDate.isBefore(currentDate)) {
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
          openingBalance = lastCycleDoc['opening_balance'];
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
