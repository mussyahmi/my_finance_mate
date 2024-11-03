// ignore_for_file: use_build_context_synchronously

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/cycle.dart';
import '../models/transaction.dart' as t;
import '../providers/accounts_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/cycle_provider.dart';
import '../providers/transactions_provider.dart';

class TransactionListPage extends StatefulWidget {
  final String? accountId;
  final String? accountToId;
  final String? type;
  final String? subType;
  final String? categoryId;

  const TransactionListPage({
    super.key,
    this.accountId,
    this.accountToId,
    this.type,
    this.subType,
    this.categoryId,
  });

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  DateTimeRange? selectedDateRange;
  String? selectedAccountId;
  String? selectedAccountToId;
  String? selectedType;
  String? selectedCategoryId;
  List<Category> categories = [];
  bool openFilter = false;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    selectedType = widget.type;
    selectedCategoryId = widget.categoryId;
    selectedAccountId = widget.accountId;
    selectedAccountToId = widget.accountToId;

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
    Cycle cycle = context.watch<CycleProvider>().cycle!;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: const Text('Transaction List'),
            centerTitle: true,
            scrolledUnderElevation: 9999,
            floating: true,
            snap: true,
            actions: [
              if (widget.subType == null)
                IconButton(
                  onPressed: () {
                    setState(() {
                      openFilter = !openFilter;
                    });
                  },
                  icon: Icon(
                      openFilter ? Icons.filter_list : Icons.filter_list_off),
                ),
            ],
            bottom: openFilter && widget.subType == null
                ? PreferredSize(
                    preferredSize: Size(double.infinity, 275.0),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0, right: 16.0, bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ElevatedButton(
                          //   onPressed: () async {
                          //     final pickedDateRange = await showDateRangePicker(
                          //       context: context,
                          //       initialDateRange: selectedDateRange,
                          //       firstDate: DateTime.now()
                          //           .subtract(const Duration(days: 365)),
                          //       lastDate: DateTime.now()
                          //           .add(const Duration(days: 365)),
                          //     );

                          //     if (pickedDateRange != null) {
                          //       setState(() {
                          //         selectedDateRange = pickedDateRange;
                          //       });
                          //     }
                          //   },
                          //   child: Text(
                          //     selectedDateRange != null
                          //         ? 'Date Range:\n${DateFormat('EE, d MMM yyyy').format(selectedDateRange!.start)} - ${DateFormat('EE, d MMM yyyy').format(selectedDateRange!.end)}'
                          //         : 'Select Date Range',
                          //     textAlign: TextAlign.center,
                          //   ),
                          // ),
                          // const SizedBox(height: 10),
                          SegmentedButton(
                            segments: const [
                              ButtonSegment(
                                value: 'spent',
                                label: Text('Spent'),
                                icon: Icon(Icons.file_upload_outlined),
                              ),
                              ButtonSegment(
                                value: 'received',
                                label: Text('Received'),
                                icon: Icon(Icons.file_download_outlined),
                              ),
                              ButtonSegment(
                                value: 'transfer',
                                label: Text('Transfer'),
                                icon: Icon(Icons.swap_horiz),
                              ),
                            ],
                            selected: {selectedType},
                            onSelectionChanged: (newSelection) {
                              setState(() {
                                selectedType = newSelection.first;
                                selectedCategoryId = null;
                                selectedAccountToId = null;
                              });

                              _fetchCategories();
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownSearch<String>(
                            selectedItem: selectedAccountId != null
                                ? context
                                    .read<AccountsProvider>()
                                    .getAccountById(selectedAccountId)
                                    .name
                                : null,
                            onChanged: (newValue) async {
                              final selectedAccount = context
                                  .read<AccountsProvider>()
                                  .getAccountByName(newValue);

                              setState(() {
                                selectedAccountId = selectedAccount.id;
                                selectedAccountToId = null;
                              });
                            },
                            items: (filter, loadProps) {
                              return context
                                  .read<AccountsProvider>()
                                  .getFilteredAccountsByName(context, filter)
                                  .map((account) => account.name)
                                  .toList();
                            },
                            decoratorProps: DropDownDecoratorProps(
                              decoration: InputDecoration(
                                labelText: 'Account',
                              ),
                              baseStyle: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            popupProps: PopupProps.menu(
                              showSearchBox: true,
                              searchDelay: const Duration(milliseconds: 500),
                              menuProps:
                                  MenuProps(surfaceTintColor: Colors.grey),
                              itemBuilder:
                                  (context, item, isDisabled, isSelected) {
                                return ListTile(title: Text(item));
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (selectedType != 'transfer')
                            DropdownSearch<String>(
                              selectedItem: selectedCategoryId != null
                                  ? context
                                      .read<CategoriesProvider>()
                                      .getCategoryById(selectedCategoryId)
                                      .name
                                  : null,
                              onChanged: (newValue) async {
                                final selectedCategory = context
                                    .read<CategoriesProvider>()
                                    .getCategoryByName(newValue);

                                setState(() {
                                  selectedCategoryId = selectedCategory.id;
                                });
                              },
                              items: (filter, loadProps) {
                                final filteredCategories = categories
                                    .where((category) => category.name
                                        .toLowerCase()
                                        .contains(filter.toLowerCase()))
                                    .toList();

                                return filteredCategories
                                    .map((category) => category.name)
                                    .toList();
                              },
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: 'Category',
                                ),
                                baseStyle: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchDelay: const Duration(milliseconds: 500),
                                menuProps:
                                    MenuProps(surfaceTintColor: Colors.grey),
                                itemBuilder:
                                    (context, item, isDisabled, isSelected) {
                                  return ListTile(title: Text(item));
                                },
                              ),
                            ),
                          if (selectedType == 'transfer')
                            DropdownSearch<String>(
                              selectedItem: selectedAccountToId != null
                                  ? context
                                      .read<AccountsProvider>()
                                      .getAccountById(selectedAccountToId)
                                      .name
                                  : null,
                              onChanged: (newValue) async {
                                final selectedAccount = context
                                    .read<AccountsProvider>()
                                    .getAccountByName(newValue);

                                setState(() {
                                  selectedAccountToId = selectedAccount.id;
                                });
                              },
                              items: (filter, loadProps) {
                                return context
                                    .read<AccountsProvider>()
                                    .getFilteredAccountsByName(context, filter)
                                    .where((account) =>
                                        account.id != selectedAccountId)
                                    .map((account) => account.name)
                                    .toList();
                              },
                              decoratorProps: DropDownDecoratorProps(
                                decoration: InputDecoration(
                                  labelText: 'Transfer To',
                                ),
                                baseStyle: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              popupProps: PopupProps.menu(
                                showSearchBox: true,
                                searchDelay: const Duration(milliseconds: 500),
                                menuProps:
                                    MenuProps(surfaceTintColor: Colors.grey),
                                itemBuilder:
                                    (context, item, isDisabled, isSelected) {
                                  return ListTile(title: Text(item));
                                },
                              ),
                            ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      selectedType = null;
                                      selectedAccountId = null;
                                      selectedCategoryId = null;
                                      selectedAccountToId = null;
                                    });
                                  },
                                  child: Text('Clear')),
                            ],
                          )
                        ],
                      ),
                    ),
                  )
                : null,
          ),
        ],
        body: Center(
          child: FutureBuilder<List<t.Transaction>>(
            future:
                context.watch<TransactionsProvider>().fetchFilteredTransactions(
                      context,
                      selectedDateRange,
                      selectedType,
                      widget.subType,
                      selectedAccountId,
                      selectedCategoryId,
                      selectedAccountToId,
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

                if (selectedCategoryId != null || widget.subType != null) {
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
                                          transactions[index - 1].dateTime.year,
                                          transactions[index - 1]
                                              .dateTime
                                              .month,
                                          transactions[index - 1].dateTime.day,
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
                                padding: EdgeInsets.fromLTRB(8, 0, 8,
                                    index + 1 == transactions.length ? 20 : 0),
                                child: Card(
                                  child: ListTile(
                                    title: transaction.type == 'transfer'
                                        ? Row(
                                            children: [
                                              Chip(
                                                label: Text(
                                                  transaction.accountName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                padding: EdgeInsets.all(0),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 4.0),
                                                child: Icon(Icons.arrow_forward,
                                                    color: Colors.grey),
                                              ),
                                              Chip(
                                                label: Text(
                                                  transaction.accountToName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                padding: EdgeInsets.all(0),
                                              ),
                                            ],
                                          )
                                        : Text(
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
                                          color: transaction.type == 'transfer'
                                              ? Colors.grey
                                              : transaction.type == 'spent'
                                                  ? Colors.red
                                                  : Colors.green),
                                    ),
                                    onTap: () {
                                      //* Show the transaction summary dialog when tapped
                                      transaction.showTransactionDetails(
                                          context, cycle);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (selectedCategoryId != null || widget.subType != null)
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
                                  color: Theme.of(context).colorScheme.primary),
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
      ),
    );
  }
}
