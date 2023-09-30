import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart' as t;
import 'transaction_form_page.dart';

class TransactionListPage extends StatefulWidget {
  final String cycleId;
  final String? type;
  final String? categoryId;
  const TransactionListPage(
      {super.key, required this.cycleId, this.type, this.categoryId});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  DateTimeRange? selectedDateRange;
  String? selectedType;
  String? selectedCategoryId;
  List<Map<String, dynamic>> categories = [];

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    selectedType = widget.type;
    selectedCategoryId = widget.categoryId;

    await _fetchCycle();
    await _fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text('Transaction List'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          //* Filters (Dropdowns)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final pickedDateRange = await showDateRangePicker(
                      context: context,
                      initialDateRange: selectedDateRange,
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
                //* Type Dropdown
                DropdownButtonFormField<String>(
                  value: selectedType,
                  onChanged: (newValue) {
                    setState(() {
                      selectedType = newValue as String;
                      selectedCategoryId = null;
                    });
                    _fetchCategories();
                  },
                  items: ['spent', 'received', 'saving'].map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child:
                          Text('${type[0].toUpperCase()}${type.substring(1)}'),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Type',
                  ),
                ),
                //* Category Dropdown
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  onChanged: (newValue) {
                    setState(() {
                      selectedCategoryId = newValue;
                    });
                  },
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category['id'],
                      child: Text(category['name']),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            color: Colors.grey,
            height: 36,
          ),
          //* Transaction List
          Expanded(
            child: FutureBuilder<List<t.Transaction>>(
              future: fetchFilteredTransactions(),
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
                  double total = 0;

                  if (selectedType != 'saving' && selectedCategoryId != null) {
                    for (var transaction in transactions!) {
                      total += double.parse(transaction.amount);
                    }
                  }

                  return Column(
                    children: [
                      Expanded(
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
                                    setState(() {});
                                    return true;
                                  } else {
                                    return false;
                                  }
                                } else if (direction ==
                                    DismissDirection.endToStart) {
                                  //* Delete action
                                  bool result = await transaction
                                      .deleteTransaction(context);

                                  return result;
                                }

                                return false;
                              },
                              child: ListTile(
                                title: Text(
                                  transaction.categoryName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                subtitle: Text(
                                  DateFormat('EE, d MMM yyyy h:mm aa')
                                      .format(transaction.dateTime),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Text(
                                  '${(transaction.type == 'spent' || transaction.type == 'saving') ? '-' : ''}RM${transaction.amount}',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: (transaction.type == 'spent' ||
                                              transaction.type == 'saving')
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
                      ),
                      if (selectedType != 'saving' &&
                          selectedCategoryId != null)
                        Column(
                          children: [
                            const Divider(
                              color: Colors.grey,
                              height: 36,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 16.0, right: 16.0, bottom: 16.0),
                              child: Text(
                                'Total: RM${total.toStringAsFixed(2)}',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchCycle() async {
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

    final lastCycleDoc = lastCycleSnapshot.docs.first;

    setState(() {
      selectedDateRange = DateTimeRange(
        start: (lastCycleDoc['start_date'] as Timestamp).toDate(),
        end: (lastCycleDoc['end_date'] as Timestamp).toDate(),
      );
    });
  }

  Future<void> _fetchCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where user is not authenticated
      return;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    CollectionReference<Map<String, dynamic>> categoriesRef;

    if (selectedType != 'saving') {
      final cyclesRef = userRef.collection('cycles').doc(widget.cycleId);
      categoriesRef = cyclesRef.collection('categories');
    } else {
      categoriesRef = userRef.collection('savings');
    }

    Query<Map<String, dynamic>> query =
        categoriesRef.where('deleted_at', isNull: true);

    if (selectedType != 'saving') {
      query = query.where('type', isEqualTo: selectedType);
    }

    final categoriesSnapshot = await query.get();

    final fetchedCategories = categoriesSnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc['name'] as String,
              'created_at': (doc['created_at'] as Timestamp).toDate()
            })
        .toList();

    //* Sort the list by alphabetical in ascending order (most recent first)
    fetchedCategories
        .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    setState(() {
      categories = fetchedCategories;
    });
  }

  Future<List<t.Transaction>> fetchFilteredTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where the user is not authenticated.
      return [];
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final transactionsRef = userRef.collection('transactions');

    Query<Map<String, dynamic>> query =
        transactionsRef.where('deleted_at', isNull: true);

    if (selectedDateRange != null) {
      query = query
          .where('date_time', isGreaterThanOrEqualTo: selectedDateRange!.start)
          .where('date_time', isLessThanOrEqualTo: selectedDateRange!.end);
    }

    if (selectedType != null) {
      query = query.where('type', isEqualTo: selectedType);
    }

    if (selectedCategoryId != null) {
      query = query.where('category_id', isEqualTo: selectedCategoryId);
    }

    final querySnapshot = await query.get();
    final transactions = querySnapshot.docs.map((doc) async {
      final data = doc.data();

      //* Fetch the category name based on the categoryId
      DocumentSnapshot<Map<String, dynamic>> categoryDoc;
      if (data['type'] != 'saving') {
        categoryDoc = await userRef
            .collection('cycles')
            .doc(data['cycle_id'])
            .collection('categories')
            .doc(data['category_id'])
            .get();
      } else {
        categoryDoc =
            await userRef.collection('savings').doc(data['category_id']).get();
      }

      final categoryName = categoryDoc['name'] as String;

      //* Map data to your Transaction class
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

    //* Sort the list as needed
    result.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return result;
  }
}
