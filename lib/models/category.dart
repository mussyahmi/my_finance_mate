// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../pages/transaction_list_page.dart';
import '../providers/categories_provider.dart';
import '../providers/transactions_provider.dart';
import '../services/message_services.dart';
import '../widgets/category_dialog.dart';
import '../extensions/string_extension.dart';
import '../widgets/custom_draggable_scrollable_sheet.dart';
import '../widgets/tag.dart';
import 'cycle.dart';

enum BudgetFilter { all, ongoing, exceeded, completed }

class Category {
  String id;
  String name;
  String type;
  String? subType;
  String note;
  String budget;
  String totalAmount;
  String cycleId;
  DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.type,
    required this.subType,
    required this.note,
    required this.budget,
    required this.totalAmount,
    required this.cycleId,
    required this.updatedAt,
  });

  String amountBalance() {
    return (double.parse(budget) - double.parse(totalAmount))
        .toStringAsFixed(2);
  }

  double progressPercentage() {
    return double.parse(totalAmount) / double.parse(budget);
  }

  Future<void> showCategoryDetails(
      BuildContext context, Cycle cycle, String selectedType) async {
    await showModalBottomSheet(
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
                        CupertinoIcons.delete_solid,
                        color: Colors.red,
                      ),
                    ),
                  if (cycle.isLastCycle)
                    IconButton.filledTonal(
                      onPressed: () async {
                        final result = await showCategoryDialog(
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
                        CupertinoIcons.pencil,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  IconButton.filledTonal(
                    onPressed: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionListPage(
                              type: selectedType, categoryId: id),
                        ),
                      );
                    },
                    icon: const Icon(
                      CupertinoIcons.list_bullet,
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
                    'ID:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SelectableText(id),
                ],
              ),
              const SizedBox(height: 5),
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
              if (type == 'spent')
                Column(
                  children: [
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Sub Type:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Tag(title: subType),
                      ],
                    ),
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
                              Text(
                                double.parse(amountBalance()) < 0
                                    ? 'Exceed:'
                                    : 'Balance:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'RM${double.parse(amountBalance()).abs().toStringAsFixed(2)}',
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
                    const SizedBox(height: 5),
                    const Text(
                      'Note:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    FleatherEditor(
                      controller: FleatherController(
                        document: ParchmentDocument.fromJson(
                          note.isNotEmpty && note.contains('insert')
                              ? jsonDecode(note)
                              : [
                                  {"insert": "$note\n"}
                                ],
                        ),
                      ),
                      showCursor: false,
                      readOnly: true,
                      onLaunchUrl: (url) {
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
                'There are transactions associated with this category in the current cycle. You cannot delete it.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
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
                  Navigator.of(context).pop(false);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  surfaceTintColor: Colors.red,
                  foregroundColor: Colors.redAccent,
                ),
                onPressed: () async {
                  final MessageService messageService = MessageService();

                  EasyLoading.show(
                      status: messageService.getRandomDeleteMessage());

                  //* Delete the item from Firestore here
                  final categoryId = id;

                  await context
                      .read<CategoriesProvider>()
                      .deleteCategory(context, categoryId);

                  EasyLoading.showSuccess(
                      messageService.getRandomDoneDeleteMessage());

                  Navigator.of(context).pop(true);
                },
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );
    }
  }

  static Future<bool> showCategoryDialog(
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
