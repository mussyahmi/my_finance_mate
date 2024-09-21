// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/transaction.dart' as t;
import '../extensions/string_extension.dart';
import '../providers/categories_provider.dart';
import '../providers/transactions_provider.dart';

class TransactionListPage extends StatefulWidget {
  final String? type;
  final String? subType;
  final String? categoryName;

  const TransactionListPage({
    super.key,
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
    selectedType = widget.type;
    selectedCategoryName = widget.categoryName;

    await _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    List<Category> fetchedCategories = List<Category>.from(await context
        .read<CategoriesProvider>()
        .getCategories(context, selectedType, 'transaction_list'));

    setState(() {
      categories = fetchedCategories;
    });
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
                              // _fetchCategories();
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
                future: context
                    .watch<TransactionsProvider>()
                    .fetchFilteredTransactions(
                      context,
                      selectedDateRange,
                      selectedType,
                      widget.subType,
                      selectedCategoryName,
                    ),
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
                              return Column(
                                children: [
                                  if (index == 0 ||
                                      DateTime(
                                              transaction.dateTime.year,
                                              transaction.dateTime.month,
                                              transaction.dateTime.day,
                                              0,
                                              0) !=
                                          DateTime(
                                              transactions[index - 1]
                                                  .dateTime
                                                  .year,
                                              transactions[index - 1]
                                                  .dateTime
                                                  .month,
                                              transactions[index - 1]
                                                  .dateTime
                                                  .day,
                                              0,
                                              0))
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        transaction.getDateText(),
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.grey),
                                      ),
                                    ),
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                        8,
                                        0,
                                        8,
                                        index + 1 == transactions.length
                                            ? 20
                                            : 0),
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
                                              .showTransactionDetails(context);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
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
}
