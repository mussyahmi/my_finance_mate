import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/category.dart';
import '../pages/transaction_list_page.dart';

enum BudgetFilter { all, ongoing, exceeded, completed }

class ForecastBudget extends StatefulWidget {
  final bool isLoading;
  final String cycleId;
  final String amountBalance;
  final Function onCategoryChanged;

  const ForecastBudget(
      {super.key,
      required this.isLoading,
      required this.cycleId,
      required this.amountBalance,
      required this.onCategoryChanged});

  @override
  State<ForecastBudget> createState() => _ForecastBudgetState();
}

class _ForecastBudgetState extends State<ForecastBudget> {
  BudgetFilter currentFilter = BudgetFilter.all;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Forecast Budget',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              TextButton.icon(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
                label: Text(currentFilter.name[0].toUpperCase() +
                    currentFilter.name.substring(1)),
              )
            ],
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<List<Category>>(
          future: _fetchBudgets(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                widget.isLoading) {
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
                  'No budgets found.',
                  textAlign: TextAlign.center,
                ),
              ); //* Display a message for no budgets
            } else {
              //* Display the list of budgets
              final budgets = snapshot.data!;
              final amountBalanceAfterBudget =
                  _getAmountBalanceAfterBudget(budgets);

              return Column(
                children: [
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 300,
                    ),
                    height: min(300, budgets.length * 120),
                    child: ListView.builder(
                      itemCount: budgets.length,
                      itemBuilder: (context, index) {
                        final budget = budgets[index];
                        double amountBalance =
                            double.parse(budget.amountBalance());

                        String thresholdText = 'Balance';
                        if (amountBalance < 0) {
                          thresholdText = 'Exceed';
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TransactionListPage(
                                      cycleId: widget.cycleId,
                                      type: 'spent',
                                      categoryName: budget.name),
                                ),
                              );
                            },
                            child: Card(
                              child: Stack(
                                children: [
                                  ListTile(
                                    key: Key(budget.id),
                                    title: Text(
                                      budget.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    subtitle: Column(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              'Spent: RM ${budget.totalAmount}',
                                            ),
                                            Text(
                                              '$thresholdText: RM ${amountBalance.abs().toStringAsFixed(2)}',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8.0),
                                        LinearProgressIndicator(
                                          value: budget.progressPercentage(),
                                          backgroundColor: Colors.grey[300],
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            () {
                                              double progress =
                                                  budget.progressPercentage();
                                              if (progress == 1.0) {
                                                return Colors
                                                    .green; //* Change color when budget is exactly 1
                                              } else if (progress > 1.0) {
                                                return Colors
                                                    .red; //* Change color when budget is greater than 1
                                              } else {
                                                return Colors
                                                    .orange; //* Change color when budget is less than 1
                                              }
                                            }(),
                                          ),
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(8.0)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top:
                                        8, //* Adjust the value to position the icon as needed
                                    right:
                                        16, //* Adjust the value to position the icon as needed
                                    child: GestureDetector(
                                      onTap: () =>
                                          budget.showCategorySummaryDialog(
                                              context,
                                              budget.type,
                                              widget.onCategoryChanged),
                                      child: Icon(
                                        Icons.info,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary, //* Change the color as needed
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (currentFilter == BudgetFilter.all ||
                      currentFilter == BudgetFilter.ongoing)
                    Column(
                      children: [
                        const SizedBox(height: 10),
                        Text(
                          'After Minus Budget\'s Balance: RM $amountBalanceAfterBudget',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    )
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Future<List<Category>> _fetchBudgets() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where the user is not authenticated.
      return [];
    }

    if (widget.cycleId.isEmpty) {
      return [];
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles').doc(widget.cycleId);
    final categoriesRef = cyclesRef.collection('categories');

    final categoryQuery = await categoriesRef
        .where('deleted_at', isNull: true)
        .where('type', isEqualTo: 'spent')
        .where('budget', isNotEqualTo: '0.00')
        .get();
    final categories = categoryQuery.docs.map((doc) async {
      final data = doc.data();

      return Category(
        id: doc.id,
        name: data['name'],
        type: data['type'],
        note: data['note'],
        budget: data['budget'],
        totalAmount: data['total_amount'],
        cycleId: widget.cycleId,
        createdAt: (data['created_at'] as Timestamp).toDate(),
        updatedAt: (data['updated_at'] as Timestamp).toDate(),
      );
    }).toList();

    var result = await Future.wait(categories);

    //* Sort the list by 'updated_at' in descending order (most recent first)
    result.sort((a, b) => (b.updatedAt).compareTo(a.updatedAt));

    //* Filter categories based on the selected filter
    List<Category> filteredBudgets;
    switch (currentFilter) {
      case BudgetFilter.ongoing:
        filteredBudgets = result
            .where((budget) => double.parse(budget.amountBalance()) > 0)
            .toList();
        break;
      case BudgetFilter.exceeded:
        filteredBudgets = result
            .where((budget) => double.parse(budget.amountBalance()) < 0)
            .toList();
        break;
      case BudgetFilter.completed:
        filteredBudgets = result
            .where((budget) => double.parse(budget.amountBalance()) <= 0)
            .toList();
        break;
      case BudgetFilter.all:
      default:
        filteredBudgets = result;
        break;
    }

    return filteredBudgets;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Filter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All'),
                onTap: () {
                  _applyFilter(BudgetFilter.all);
                  Navigator.pop(context);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                selected: currentFilter == BudgetFilter.all,
                selectedColor: Theme.of(context).colorScheme.onPrimary,
                selectedTileColor: Theme.of(context).colorScheme.primary,
              ),
              ListTile(
                title: const Text('Ongoing'),
                onTap: () {
                  _applyFilter(BudgetFilter.ongoing);
                  Navigator.pop(context);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                selected: currentFilter == BudgetFilter.ongoing,
                selectedColor: Theme.of(context).colorScheme.onPrimary,
                selectedTileColor: Theme.of(context).colorScheme.primary,
              ),
              ListTile(
                title: const Text('Exceeded'),
                onTap: () {
                  _applyFilter(BudgetFilter.exceeded);
                  Navigator.pop(context);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                selected: currentFilter == BudgetFilter.exceeded,
                selectedColor: Theme.of(context).colorScheme.onPrimary,
                selectedTileColor: Theme.of(context).colorScheme.primary,
              ),
              ListTile(
                title: const Text('Completed'),
                onTap: () {
                  _applyFilter(BudgetFilter.completed);
                  Navigator.pop(context);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                selected: currentFilter == BudgetFilter.completed,
                selectedColor: Theme.of(context).colorScheme.onPrimary,
                selectedTileColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyFilter(BudgetFilter filter) {
    setState(() {
      currentFilter = filter;
    });
  }

  String _getAmountBalanceAfterBudget(List<Category> budgets) {
    double budgetBalance = double.parse(widget.amountBalance);

    for (var budget in budgets) {
      if (budget.budget != '0.00') {
        budgetBalance -= double.parse(budget.amountBalance()) < 0
            ? 0
            : double.parse(budget.amountBalance());
      }
    }

    //* Fix value -0.00
    if (budgetBalance < 0 && budgetBalance > -0.01) {
      budgetBalance = budgetBalance.abs();
    }

    return budgetBalance.toStringAsFixed(2);
  }
}
