// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';

import '../models/debt.dart';
import '../providers/debt_provider.dart';
import '../widgets/debt_summary.dart';

class DebtTrackerPage extends StatefulWidget {
  const DebtTrackerPage({super.key});

  @override
  State<DebtTrackerPage> createState() => _DebtTrackerPageState();
}

class _DebtTrackerPageState extends State<DebtTrackerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Debt.showDebtDialog(context, 'Add');
        },
        child: const Icon(Icons.add),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const SliverAppBar(
            title: Text('Debt Tracker'),
            centerTitle: true,
            scrolledUnderElevation: 9999,
            floating: true,
            snap: true,
          ),
        ],
        body: Center(
          child: FutureBuilder(
            future: context.watch<DebtProvider>().getDebts(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text("No debts found.");
              } else {
                final debts = snapshot.data!;

                final totalIOwe = debts
                    .where((d) => d.type == DebtType.iOwe)
                    .fold<double>(0, (sum, d) => sum + double.parse(d.amount));

                final totalTheyOwe = debts
                    .where((d) => d.type == DebtType.theyOweMe)
                    .fold<double>(0, (sum, d) => sum + double.parse(d.amount));

                final net = totalTheyOwe - totalIOwe;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          DebtSummary(
                            net: net,
                            totalIOwe: totalIOwe,
                            totalTheyOwe: totalTheyOwe,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: debts.length,
                        itemBuilder: (context, index) {
                          final debt = debts[index];

                          return Column(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Card(
                                  child: ListTile(
                                      title: Text(
                                        debt.personName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            debt.type == DebtType.iOwe
                                                ? "I Owe RM${debt.amount}"
                                                : "They Owe Me RM${debt.amount}",
                                            style: TextStyle(
                                              color: debt.type == DebtType.iOwe
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                          ),
                                          Text(
                                            debt.note.contains('insert')
                                                ? ParchmentDocument.fromJson(
                                                        jsonDecode(debt.note))
                                                    .toPlainText()
                                                : debt.note.split('\\n')[0],
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                            CupertinoIcons.check_mark_circled),
                                        tooltip: "Mark as settled",
                                        onPressed: () async {
                                          final confirm =
                                              await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text("Confirm"),
                                              content: const Text(
                                                  "Are you sure you want to mark this debt as settled?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(false),
                                                  child: const Text("Cancel"),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                    foregroundColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .onPrimary,
                                                  ),
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(true),
                                                  child: const Text("Yes"),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            await context
                                                .read<DebtProvider>()
                                                .deleteDebt(context, debt.id);

                                            EasyLoading.showSuccess(
                                                "Debt marked as settled");
                                          }
                                        },
                                      ),
                                      onTap: () async {
                                        await Debt.showDebtDialog(
                                            context, 'Edit',
                                            debt: debt);
                                      }),
                                ),
                              ),
                              if (index == debts.length - 1)
                                const SizedBox(height: 80),
                            ],
                          );
                        },
                      ),
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
