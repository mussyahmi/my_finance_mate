// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pages/transaction_list_page.dart';
import '../widgets/category_dialog.dart';
import '../extensions/string_extension.dart';
import '../widgets/custom_draggable_scrollable_sheet.dart';
import 'cycle.dart';
import '../extensions/firestore_extensions.dart';
import 'person.dart';

enum BudgetFilter { all, ongoing, exceeded, completed }

class Category {
  final String id;
  final String name;
  final String type;
  final String note;
  final String budget;
  final String totalAmount;
  final String cycleId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.note,
    required this.budget,
    required this.totalAmount,
    required this.cycleId,
    required this.createdAt,
    required this.updatedAt,
  });

  static Future<List<Category>> fetchBudgets(
    Person user,
    Cycle? cycle,
    BudgetFilter currentFilter,
  ) async {
    if (cycle == null) {
      return [];
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles').doc(cycle.id);
    final categoriesRef = cyclesRef.collection('categories');

    final categorySnapshot = await categoriesRef
        .where('deleted_at', isNull: true)
        .where('type', isEqualTo: 'spent')
        .where('budget', isNotEqualTo: '0.00')
        .getSavy();

    final categories = categorySnapshot.docs.map((doc) async {
      final data = doc.data();

      return Category(
        id: doc.id,
        name: data['name'],
        type: data['type'],
        note: data['note'],
        budget: data['budget'],
        totalAmount: data['total_amount'],
        cycleId: cycle.id,
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

  String amountBalance() {
    return (double.parse(budget) - double.parse(totalAmount))
        .toStringAsFixed(2);
  }

  double progressPercentage() {
    return double.parse(totalAmount) / double.parse(budget);
  }

  void showCategoryDetails(BuildContext context, Person user, Cycle cycle,
      String selectedType, Function onCategoryChanged) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return CustomDraggableScrollableSheet(
          initialSize: 0.45,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Category Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () async {
                      final result = await _deleteHandler(
                          context, user, onCategoryChanged);

                      if (result) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () async {
                      final result = await showCategoryFormDialog(
                        context,
                        user,
                        cycleId,
                        selectedType,
                        'Edit',
                        onCategoryChanged,
                        category: this,
                      );

                      if (result) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionListPage(
                              user: user,
                              cycle: cycle,
                              type: 'spent',
                              categoryName: name),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.list,
                    ),
                  ),
                ],
              )
            ],
          ),
          contents: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Name:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(name),
                ],
              ),
              if (budget.isNotEmpty && budget != '0.00')
                Column(
                  children: [
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Budget:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('RM$budget'),
                      ],
                    ),
                  ],
                ),
              if (totalAmount != '0.00')
                Column(
                  children: [
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${type.capitalize()}:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('RM$totalAmount'),
                      ],
                    ),
                    if (budget.isNotEmpty && budget != '0.00')
                      Column(
                        children: [
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Balance:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'RM${(double.parse(budget) - double.parse(totalAmount)).toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              if (note.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Note:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    MarkdownBody(
                      data: note.replaceAll('\n', '  \n'),
                      selectable: true,
                      onTapLink: (text, url, title) {
                        launchUrl(Uri.parse(url!));
                      },
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _deleteHandler(
    context,
    Person user,
    Function onCategoryChanged,
  ) async {
    //* Check if there are transactions associated with this category
    final hasTransactions = await this.hasTransactions(user);

    if (hasTransactions) {
      //* If there are transactions, show an error message or handle it accordingly.
      return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Cannot Delete Category'),
            content: const Text(
                'There are transactions associated with this category. You cannot delete it.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false); //* Close the dialog
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      //* If there are no transactions, proceed with the deletion.
      return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Delete'),
            content:
                const Text('Are you sure you want to delete this category?'),
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
                  final categoryId = id;

                  final userRef = FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid);
                  final cyclesRef = userRef.collection('cycles').doc(cycleId);
                  final categoriesRef = cyclesRef.collection('categories');
                  final categoryRef = categoriesRef.doc(categoryId);

                  //* Update the 'deleted_at' field with the current timestamp
                  final now = DateTime.now();
                  categoryRef.update({
                    'updated_at': now,
                    'deleted_at': now,
                  });

                  onCategoryChanged();

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

  Future<bool> hasTransactions(Person user) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final transactionsRef = userRef.collection('transactions');

    final transactionsSnapshot = await transactionsRef
        .where('category_id', isEqualTo: id)
        .where('deleted_at', isNull: true)
        .limit(1)
        .getSavy();

    return transactionsSnapshot.docs.isNotEmpty;
  }

  static Future<void> updateCategoryNameForAllTransactions(Person user) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final transactionsRef = userRef.collection('transactions');

    final transactionsSnapshot = await transactionsRef.getSavy();

    print('initiate updateCategoryNameForAllTransactions');

    for (var doc in transactionsSnapshot.docs) {
      final data = doc.data();

      DocumentSnapshot<Map<String, dynamic>> categoryDoc;
      categoryDoc = await userRef
          .collection('cycles')
          .doc(data['cycle_id'])
          .collection('categories')
          .doc(data['category_id'])
          .getSavy();

      final categoryName = categoryDoc['name'] as String;

      await transactionsRef.doc(doc.id).update({'category_name': categoryName});
    }

    print('done updateCategoryNameForAllTransactions');
  }

  static Future<void> recalculateCategoryAndCycleTotalAmount(
    Person user,
    String cycleId,
  ) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles').doc(cycleId);
    final categoriesRef = cyclesRef.collection('categories');

    final cycleSnapshot = await cyclesRef.getSavy();
    final categoriesSnapshot = await categoriesRef.getSavy();

    //* Get current timestamp
    final now = DateTime.now();

    print('initiate recalculateCategoryTotalAmount');

    double totalAmountSpent = 0;
    double totalAmountReceived = 0;

    for (var doc in categoriesSnapshot.docs) {
      final transactionsRef = userRef.collection('transactions');

      final transactionsSnapshot = await transactionsRef
          .where('cycle_id', isEqualTo: cycleId)
          .where('category_id', isEqualTo: doc.id)
          .where('deleted_at', isNull: true)
          .getSavy();

      double totalAmount = 0;

      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();

        totalAmount += double.parse(data['amount']);

        if (data['type'] == 'spent') {
          totalAmountSpent += double.parse(data['amount']);
        } else {
          totalAmountReceived += double.parse(data['amount']);
        }
      }

      //* Update each cateogry's data
      await categoriesRef.doc(doc.id).update({
        'total_amount': totalAmount.toStringAsFixed(2),
        'updated_at': now,
      });
    }

    if (cycleSnapshot.exists) {
      final cycleData = cycleSnapshot.data() as Map<String, dynamic>;

      final double cycleOpeningBalance =
          double.parse(cycleData['opening_balance']);

      //* Update the cycle document
      await cyclesRef.update({
        'amount_spent': totalAmountSpent.toStringAsFixed(2),
        'amount_received': totalAmountReceived.toStringAsFixed(2),
        'amount_balance':
            (cycleOpeningBalance + totalAmountReceived - totalAmountSpent)
                .toStringAsFixed(2),
        'updated_at': now,
      });
    }

    print('done recalculateCategoryTotalAmount');
  }

  static Future<List<Category>> fetchCategories(Person user, String cycleId,
      [String? type, bool isUniqueCategoryNames = false]) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles').doc(cycleId);
    final categoriesRef = cyclesRef.collection('categories');

    Query<Map<String, dynamic>> categoriesQuery =
        categoriesRef.where('deleted_at', isNull: true);

    if (type != null) {
      categoriesQuery = categoriesQuery.where('type', isEqualTo: type);
    }

    final categoriesSnapshot = await categoriesQuery.getSavy();

    List<Category> fetchedCategories = categoriesSnapshot.docs
        .map((doc) => Category(
              id: doc.id,
              name: doc['name'],
              type: doc['type'],
              note: doc['note'],
              budget: doc['budget'],
              totalAmount: doc['total_amount'],
              cycleId: cycleId,
              createdAt: (doc['created_at'] as Timestamp).toDate(),
              updatedAt: (doc['updated_at'] as Timestamp).toDate(),
            ))
        .toList();

    if (isUniqueCategoryNames) {
      final Set<String> uniqueCategoryNames = {};
      final List<Category> filteredCategories = [];

      for (var doc in categoriesSnapshot.docs) {
        final categoryName = doc['name'] as String;
        if (!uniqueCategoryNames.contains(categoryName)) {
          uniqueCategoryNames.add(categoryName);

          final category = Category(
            id: doc.id,
            name: categoryName,
            type: doc['type'],
            note: doc['note'],
            budget: doc['budget'],
            totalAmount: doc['total_amount'],
            cycleId: cycleId,
            createdAt: (doc['created_at'] as Timestamp).toDate(),
            updatedAt: (doc['updated_at'] as Timestamp).toDate(),
          );

          filteredCategories.add(category);
        }
      }

      fetchedCategories = filteredCategories;
    }

    //* Sort the list by alphabetical in ascending order (most recent first)
    fetchedCategories.sort((a, b) => (a.name).compareTo(b.name));

    return fetchedCategories;
  }

  //* Function to show the add/edit category dialog
  static Future<bool> showCategoryFormDialog(
      BuildContext context,
      Person user,
      String cycleId,
      String selectedType,
      String action,
      Function onCategoryChanged,
      {Category? category}) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return CategoryDialog(
          user: user,
          cycleId: cycleId,
          type: selectedType,
          action: action,
          category: category,
          onCategoryChanged: onCategoryChanged,
        );
      },
    );
  }
}
