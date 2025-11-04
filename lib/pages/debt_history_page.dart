// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:fleather/fleather.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import '../models/debt.dart';
import '../providers/debt_provider.dart';

class DebtHistoryPage extends StatefulWidget {
  const DebtHistoryPage({super.key});

  @override
  State<DebtHistoryPage> createState() => _DebtHistoryPageState();
}

class _DebtHistoryPageState extends State<DebtHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settled Debts'),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: context.watch<DebtProvider>().getSettledDebts(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No settled debts found.'));
          } else {
            final debts = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: debts.length,
              itemBuilder: (context, index) {
                final debt = debts[index];

                return Card(
                  child: ListTile(
                    title: Text(
                      debt.personName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.type == DebtType.iOwe
                              ? "I Owed RM${debt.amount}"
                              : "They Owed Me RM${debt.amount}",
                          style: TextStyle(
                            color: debt.type == DebtType.iOwe
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        Text(
                          debt.note.contains('insert')
                              ? ParchmentDocument.fromJson(
                                  jsonDecode(debt.note),
                                ).toPlainText()
                              : debt.note.split('\\n')[0],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ✅ UNDO button (check mark icon)
                        IconButton(
                          icon: Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          tooltip: 'Mark as Unsettled',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Confirm"),
                                content: const Text(
                                    "Do you want to mark this debt as unsettled again?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text("Yes"),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await context
                                  .read<DebtProvider>()
                                  .toggleSettleDebt(context, debt);

                              EasyLoading.showSuccess(
                                  "Debt marked as unsettled again.");
                            }
                          },
                        ),

                        // 🗑️ DELETE button
                        IconButton(
                          icon: const Icon(
                            CupertinoIcons.delete_solid,
                            color: Colors.red,
                          ),
                          tooltip: 'Delete Debt',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Confirm"),
                                content: const Text(
                                    "Are you sure you want to permanently delete this debt?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text("Delete"),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await context
                                  .read<DebtProvider>()
                                  .deleteDebt(context, debt);

                              EasyLoading.showSuccess("Debt deleted");
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
