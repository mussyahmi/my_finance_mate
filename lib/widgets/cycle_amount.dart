import 'package:flutter/material.dart';

import '../pages/transaction_list_page.dart';

class CycleAmount extends StatefulWidget {
  final String cycleId;
  final String amountBalance;
  final String openingBalance;
  final String amountReceived;
  final String amountSpent;

  const CycleAmount({
    super.key,
    required this.cycleId,
    required this.amountBalance,
    required this.openingBalance,
    required this.amountReceived,
    required this.amountSpent,
  });

  @override
  State<CycleAmount> createState() => _CycleAmountState();
}

class _CycleAmountState extends State<CycleAmount> {
  bool _isAmountVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 3,
          margin: const EdgeInsets.all(16),
          child: Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Available Balance',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      !_isAmountVisible
                          ? 'RM ****'
                          : 'RM ${widget.amountBalance}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Opening Balance: ${!_isAmountVisible ? 'RM ****' : 'RM ${widget.openingBalance}'}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  iconSize: 20,
                  onPressed: () {
                    setState(() {
                      _isAmountVisible = !_isAmountVisible;
                    });
                  },
                  icon: Icon(
                    _isAmountVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              )
            ],
          ),
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
                        cycleId: widget.cycleId,
                        type: 'received',
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  margin: const EdgeInsets.fromLTRB(16, 0, 8, 16),
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
                        Text(
                          !_isAmountVisible
                              ? 'RM ****'
                              : 'RM ${widget.amountReceived}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
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
                        cycleId: widget.cycleId,
                        type: 'spent',
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 3,
                  margin: const EdgeInsets.fromLTRB(8, 0, 16, 16),
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
                        Text(
                          !_isAmountVisible
                              ? 'RM ****'
                              : 'RM ${widget.amountSpent}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
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
    );
  }
}
