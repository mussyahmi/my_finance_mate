// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pages/transaction_list_page.dart';
import '../providers/categories_provider.dart';
import '../providers/transactions_provider.dart';
import '../widgets/category_dialog.dart';
import '../extensions/string_extension.dart';
import '../widgets/custom_draggable_scrollable_sheet.dart';
import '../extensions/firestore_extensions.dart';
import 'cycle.dart';
import 'person.dart';

enum BudgetFilter { all, ongoing, exceeded, completed }

class Category {
  String id;
  String name;
  String type;
  String note;
  String budget;
  String totalAmount;
  String cycleId;
  DateTime createdAt;
  DateTime updatedAt;

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

  String amountBalance() {
    return (double.parse(budget) - double.parse(totalAmount))
        .toStringAsFixed(2);
  }

  double progressPercentage() {
    return double.parse(totalAmount) / double.parse(budget);
  }

  void showCategoryDetails(
      BuildContext context, Cycle cycle, String selectedType) {
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
                  if (cycle.isLastCycle)
                    IconButton.filledTonal(
                      onPressed: () async {
                        final result = await _deleteHandler(context);

                        if (result) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                    ),
                  if (cycle.isLastCycle)
                    IconButton.filledTonal(
                      onPressed: () async {
                        final result = await showCategoryFormDialog(
                          context,
                          selectedType,
                          'Edit',
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
                              type: 'spent', categoryName: name),
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
    BuildContext context,
  ) async {
    //* Check if there are transactions associated with this category
    final transactionFound =
        context.read<TransactionsProvider>().hasCategory(id);

    if (transactionFound) {
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

                  await context
                      .read<CategoriesProvider>()
                      .deleteCategory(context, categoryId);

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

  static Future<void> updateCategoryNameForAllTransactions(Person user) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final transactionsRef = userRef.collection('transactions');

    final transactionsSnapshot = await transactionsRef.getSavy();
    print(
        'updateCategoryNameForAllTransactions: ${transactionsSnapshot.docs.length}');

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
      print('updateCategoryNameForAllTransactions - categoryDoc: 1');

      final categoryName = categoryDoc['name'] as String;

      await transactionsRef.doc(doc.id).update({'category_name': categoryName});
    }

    print('done updateCategoryNameForAllTransactions');
  }

  //* Function to show the add/edit category dialog
  static Future<bool> showCategoryFormDialog(
      BuildContext context, String selectedType, String action,
      {Category? category}) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return CategoryDialog(
          type: selectedType,
          action: action,
          category: category,
        );
      },
    );
  }
}
