import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category.dart';
import '../extensions/string_extension.dart';
import '../models/cycle.dart';
import '../providers/categories_provider.dart';
import '../providers/cycle_provider.dart';
import '../widgets/custom_draggable_scrollable_sheet.dart';

class ForecastBudget extends StatefulWidget {
  const ForecastBudget({super.key});

  @override
  State<ForecastBudget> createState() => _ForecastBudgetState();
}

class _ForecastBudgetState extends State<ForecastBudget> {
  late SharedPreferences prefs;
  BudgetFilter currentFilter = BudgetFilter.all;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    SharedPreferences? sharedPreferences =
        await SharedPreferences.getInstance();
    final savedFilter = sharedPreferences.getString('forecast_filter');

    setState(() {
      prefs = sharedPreferences;
      currentFilter = savedFilter != null
          ? BudgetFilter.values.firstWhere(
              (filter) => filter.toString() == savedFilter,
              orElse: () => BudgetFilter
                  .all, //* Set a default filter if savedFilter is null or invalid
            )
          : BudgetFilter
              .all; //* Set a default filter if 'forecast_filter' is not saved
    });
  }

  @override
  Widget build(BuildContext context) {
    Cycle? cycle = context.watch<CycleProvider>().cycle;

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
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return CustomDraggableScrollableSheet(
                        initialSize: 0.8,
                        title: const Column(
                          children: [
                            Text(
                              'Select Filter',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            SizedBox(height: 10),
                          ],
                        ),
                        contents: Column(
                          children: [
                            _listTile('all'),
                            _listTile('ongoing'),
                            _listTile('exceeded'),
                            _listTile('completed'),
                          ],
                        ),
                      );
                    },
                  );
                },
                label: Text(currentFilter.name.capitalize()),
              )
            ],
          ),
        ),
        FutureBuilder<List<Category>>(
          future: context.watch<CategoriesProvider>().getBudgets(currentFilter),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                cycle == null) {
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
                  _getAmountBalanceAfterBudget(cycle, budgets);

              return Column(
                children: [
                  if (currentFilter == BudgetFilter.all ||
                      currentFilter == BudgetFilter.ongoing)
                    Column(
                      children: [
                        Text(
                          'After Minus Budget\'s Balance: RM $amountBalanceAfterBudget',
                          style: const TextStyle(
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 300,
                    ),
                    height: min(300, budgets.length * 120),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
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
                          child: Card(
                            child: ListTile(
                              key: Key(budget.id),
                              title: Text(
                                budget.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
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
                                              .deepOrange; //* Change color when budget is less than 1
                                        }
                                      }(),
                                    ),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(8.0)),
                                  ),
                                ],
                              ),
                              onTap: () {
                                budget.showCategoryDetails(
                                    context, cycle, budget.type);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  void _applyFilter(BudgetFilter filter) async {
    await prefs.setString(
        'forecast_filter',
        filter
            .toString()); //* Store the string representation of the enum value

    setState(() {
      currentFilter = filter;
    });
  }

  String _getAmountBalanceAfterBudget(Cycle cycle, List<Category> budgets) {
    double budgetBalance = double.parse(cycle.amountBalance);

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

  ListTile _listTile(String type) {
    BudgetFilter budgetFilter = BudgetFilter.values
        .firstWhere((e) => e.toString().split('.').last == type);

    return ListTile(
      title: Text(
        type.capitalize(),
        style: TextStyle(
            fontWeight: currentFilter == budgetFilter
                ? FontWeight.bold
                : FontWeight.normal),
      ),
      onTap: () {
        _applyFilter(budgetFilter);
        Navigator.pop(context);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      selected: currentFilter == budgetFilter,
      selectedColor: Theme.of(context).colorScheme.onPrimary,
      selectedTileColor: Theme.of(context).colorScheme.primary,
    );
  }
}
