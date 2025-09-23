// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

import '../pages/transaction_list_page.dart';
import '../providers/accounts_provider.dart';
import '../providers/transactions_provider.dart';
import '../services/message_services.dart';
import '../widgets/account_dialog.dart';
import '../widgets/custom_draggable_scrollable_sheet.dart';
import 'cycle.dart';

class Account {
  String id;
  String name;
  String openingBalance;
  String amountBalance;
  String amountReceived;
  String amountSpent;
  String cycleId;
  DateTime createdAt;
  bool isExcluded;

  Account({
    required this.id,
    required this.name,
    required this.openingBalance,
    required this.amountBalance,
    required this.amountReceived,
    required this.amountSpent,
    required this.cycleId,
    required this.createdAt,
    required this.isExcluded,
  });

  void showAccountDetails(BuildContext context, Cycle cycle) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return CustomDraggableScrollableSheet(
          initialSize: 0.55,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Account Details',
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
                        final result = await showAccountDialog(
                          context,
                          cycle,
                          'Edit',
                          account: this,
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
                          builder: (context) =>
                              TransactionListPage(accountId: id),
                        ),
                      );
                    },
                    icon: const Icon(
                      CupertinoIcons.list_bullet,
                    ),
                  ),
                ],
              ),
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
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Net Balance:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                      '${double.parse(amountBalance) < 0 ? '-' : ''}RM${amountBalance.replaceFirst('-', '')}'),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Opening Balance:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('RM$openingBalance'),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amount Received:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('RM$amountReceived'),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Amount Spent:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('RM$amountSpent'),
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
        context.read<TransactionsProvider>().hasAccount(id);

    if (transactionFound) {
      //* If there are transactions, show an error message or handle it accordingly.
      return await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Cannot Delete Account'),
            content: const Text(
                'There are transactions associated with this account in the current cycle. You cannot delete it.'),
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
                const Text('Are you sure you want to delete this account?'),
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
                  await context
                      .read<AccountsProvider>()
                      .deleteAccount(context, this);

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

  static Future<bool> showAccountDialog(
      BuildContext context, Cycle cycle, String action,
      {Account? account, bool? isTourMode}) async {
    return await showDialog(
          context: context,
          builder: (context) {
            return ShowCaseWidget(
              builder: (showcaseContext) => AccountDialog(
                cycle: cycle,
                action: action,
                account: account,
                isTourMode: isTourMode,
                showcaseContext: showcaseContext,
              ),
              globalFloatingActionWidget: (showcaseContext) =>
                  FloatingActionWidget(
                right: 16,
                top: 16,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      ShowCaseWidget.of(showcaseContext).dismiss();
                      Navigator.of(context).pop(false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(
                      'Skip Tour',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ) ??
        false;
  }
}
