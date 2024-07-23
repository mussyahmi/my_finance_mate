// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/category.dart';
import '../models/cycle.dart';
import '../models/transaction.dart' as t;
import '../extensions/string_extension.dart';

class TransactionListPage extends StatefulWidget {
  final Cycle cycle;
  final String? type;
  final String? subType;
  final String? categoryName;
  const TransactionListPage({
    super.key,
    required this.cycle,
    this.type,
    this.subType,
    this.categoryName,
  });

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  DateTimeRange? selectedDateRange;
  String? selectedType;
  String? selectedCategoryName;
  List<Category> categories = [];

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    selectedDateRange = DateTimeRange(
      start: widget.cycle.startDate,
      end: widget.cycle.endDate,
    );
    selectedType = widget.type;
    selectedCategoryName = widget.categoryName;

    await _fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: const Text('Transaction List'),
            centerTitle: true,
            scrolledUnderElevation: 9999,
            floating: true,
            snap: true,
            bottom: widget.subType == null
                ? PreferredSize(
                    preferredSize: const Size(double.infinity, 200.0),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0, right: 16.0, bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final pickedDateRange = await showDateRangePicker(
                                context: context,
                                initialDateRange: selectedDateRange,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
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
                                selectedCategoryName = null;
                              });
                              _fetchCategories();
                            },
                            items: ['spent', 'received'].map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type.capitalize()),
                              );
                            }).toList(),
                            decoration: const InputDecoration(
                              labelText: 'Type',
                            ),
                          ),
                          //* Category Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedCategoryName,
                            onChanged: (newValue) {
                              setState(() {
                                selectedCategoryName = newValue;
                              });
                            },
                            items: categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category.name,
                                child: Text(category.name),
                              );
                            }).toList(),
                            decoration: const InputDecoration(
                              labelText: 'Category',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
          ),
        ],
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

                    if (selectedCategoryName != null ||
                        widget.subType != null) {
                      for (var transaction in transactions!) {
                        if (transaction.type == 'spent') {
                          total -= double.parse(transaction.amount);
                        } else {
                          total += double.parse(transaction.amount);
                        }
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
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Card(
                                  child: ListTile(
                                    title: Text(
                                      transaction.categoryName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                      transaction.showTransactionDetails(
                                          context, () => setState(() {}));
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (selectedCategoryName != null ||
                            widget.subType != null)
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
                                  'Total: ${total < 0 ? '-' : ''}RM${total.abs().toStringAsFixed(2)}',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
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
      ),
    );
  }

  Future<void> _fetchCategories() async {
    final fetchedCategories =
        await Category.fetchCategories(widget.cycle.id, selectedType, true);

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

    if (widget.subType != null) {
      query = query.where('type', isEqualTo: 'spent');

      if (widget.subType != 'others') {
        query = query.where('subType', isEqualTo: widget.subType);
      }
    } else {
      if (selectedType != null) {
        query = query.where('type', isEqualTo: selectedType);
      }

      if (selectedCategoryName != null) {
        query = query.where('category_name', isEqualTo: selectedCategoryName);
      }
    }

    final querySnapshot = await query.get();

    List<t.Transaction> transactions = [];

    for (var doc in querySnapshot.docs) {
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

      //* Map data to your Transaction class
      if (widget.subType == 'others') {
        if (!data.containsKey('subType') || data['subType'] == null) {
          transactions = [
            ...transactions,
            t.Transaction(
              id: doc.id,
              cycleId: data['cycle_id'],
              dateTime: (data['date_time'] as Timestamp).toDate(),
              type: data['type'] as String,
              subType: data['subType'],
              categoryId: data['category_id'],
              categoryName: categoryName,
              amount: data['amount'] as String,
              note: data['note'] as String,
              files: data['files'] != null ? data['files'] as List : [],
              //* Add other transaction properties as needed
            )
          ];
        }
      } else {
        transactions = [
          ...transactions,
          t.Transaction(
            id: doc.id,
            cycleId: data['cycle_id'],
            dateTime: (data['date_time'] as Timestamp).toDate(),
            type: data['type'] as String,
            subType: data['subType'],
            categoryId: data['category_id'],
            categoryName: categoryName,
            amount: data['amount'] as String,
            note: data['note'] as String,
            files: data['files'] != null ? data['files'] as List : [],
            //* Add other transaction properties as needed
          )
        ];
      }
    }
    // }).toList();

    var result = transactions;

    //* Sort the list as needed
    result.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return result;
  }
}
