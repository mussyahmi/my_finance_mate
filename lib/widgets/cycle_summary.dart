// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cycle.dart';
import '../pages/transaction_list_page.dart';
import '../providers/cycle_provider.dart';

class CycleSummary extends StatefulWidget {
  const CycleSummary({super.key});

  @override
  State<CycleSummary> createState() => _CycleSummaryState();
}

class _CycleSummaryState extends State<CycleSummary> {
  late SharedPreferences prefs;
  bool _isAmountVisible = false;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    SharedPreferences? sharedPreferences =
        await SharedPreferences.getInstance();

    final savedIsCycleSummaryVisible =
        sharedPreferences.getBool('is_cycle_summary_visible');

    setState(() {
      prefs = sharedPreferences;
      _isAmountVisible = savedIsCycleSummaryVisible ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Cycle? cycle = context.watch<CycleProvider>().cycle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 3,
          margin: const EdgeInsets.fromLTRB(8, 16, 8, 16),
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Net Balance',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      !_isAmountVisible
                          ? 'RM****'
                          : cycle != null
                              ? '${double.parse(cycle.amountBalance) < 0 ? '-' : ''}RM${cycle.amountBalance.replaceFirst('-', '')}'
                              : 'RM0.00',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Opening Balance: ${!_isAmountVisible ? 'RM****' : 'RM${cycle != null ? cycle.openingBalance : '0.00'}'}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const Divider(
                      color: Colors.grey,
                      height: 36,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: cycle != null
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const TransactionListPage(
                                          type: 'received',
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            child: Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(left: 8, right: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Received',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        !_isAmountVisible
                                            ? 'RM****'
                                            : 'RM${cycle != null ? cycle.amountReceived : '0.00'}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: cycle != null
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const TransactionListPage(
                                          type: 'spent',
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            child: Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(left: 16, right: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Spent',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        !_isAmountVisible
                                            ? 'RM****'
                                            : 'RM${cycle != null ? cycle.amountSpent : '0.00'}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (cycle != null)
                Positioned(
                  top: 4,
                  left: 4,
                  child: IconButton(
                    iconSize: 20,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Recalculate Cycle Amounts'),
                            content: const Text(
                                'Are you sure you want to recalculate the cycle amounts?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                                onPressed: () async {
                                  EasyLoading.show(
                                    dismissOnTap: false,
                                    status: 'Recalculating...',
                                  );

                                  bool? status = await context
                                      .read<CycleProvider>()
                                      .recalculateCycleAmounts(context, cycle);

                                  if (status == true) {
                                    EasyLoading.showSuccess(
                                      'Cycle amounts recalculated successfully',
                                    );
                                  } else {
                                    EasyLoading.showInfo(
                                      'Cycle amounts are already up to date',
                                    );
                                  }

                                  Navigator.of(context).pop();
                                },
                                child: const Text('Recalculate'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: Icon(
                      CupertinoIcons.refresh,
                    ),
                  ),
                ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  iconSize: 20,
                  onPressed: () async {
                    await prefs.setBool(
                        'is_cycle_summary_visible', !_isAmountVisible);

                    setState(() {
                      _isAmountVisible = !_isAmountVisible;
                    });
                  },
                  icon: Icon(
                    _isAmountVisible
                        ? CupertinoIcons.eye_fill
                        : CupertinoIcons.eye_slash_fill,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
