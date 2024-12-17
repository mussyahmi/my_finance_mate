import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/account.dart';
import '../models/cycle.dart';
import '../pages/transaction_list_page.dart';
import '../providers/cycle_provider.dart';

class AccountSummary extends StatefulWidget {
  final Account account;
  const AccountSummary({super.key, required this.account});

  @override
  State<AccountSummary> createState() => _AccountSummaryState();
}

class _AccountSummaryState extends State<AccountSummary> {
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

    final savedIsCycleSummaryVisible = sharedPreferences
        .getBool('is_account_summary_visible_${widget.account.name}');

    setState(() {
      prefs = sharedPreferences;
      _isAmountVisible = savedIsCycleSummaryVisible ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Cycle cycle = context.watch<CycleProvider>().cycle!;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(8),
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  widget.account.name,
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
                      : 'RM${widget.account.amountBalance}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Opening Balance: ${!_isAmountVisible ? 'RM****' : 'RM${widget.account.openingBalance}'}',
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionListPage(
                                accountId: widget.account.id,
                                type: 'received',
                              ),
                            ),
                          );
                        },
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
                                        : 'RM${widget.account.amountReceived}',
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionListPage(
                                accountId: widget.account.id,
                                type: 'spent',
                              ),
                            ),
                          );
                        },
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
                                        : 'RM${widget.account.amountSpent}',
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
          Positioned(
            top: 4,
            left: 4,
            child: IconButton(
              iconSize: 20,
              onPressed: () {
                widget.account.showAccountDetails(context, cycle);
              },
              icon: Icon(CupertinoIcons.info_circle_fill),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              iconSize: 20,
              onPressed: () async {
                await prefs.setBool(
                    'is_account_summary_visible_${widget.account.name}',
                    !_isAmountVisible);

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
          )
        ],
      ),
    );
  }
}
