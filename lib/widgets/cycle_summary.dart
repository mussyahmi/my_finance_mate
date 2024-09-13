import 'package:flutter/material.dart';

import '../models/cycle.dart';
import '../pages/transaction_list_page.dart';

class CycleSummary extends StatefulWidget {
  final Cycle? cycle;

  const CycleSummary({
    super.key,
    required this.cycle,
  });

  @override
  State<CycleSummary> createState() => _CycleSummaryState();
}

class _CycleSummaryState extends State<CycleSummary> {
  bool _isAmountVisible = false;

  @override
  Widget build(BuildContext context) {
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
                          : 'RM ${widget.cycle?.amountBalance ?? '0.00'}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Opening Balance: ${!_isAmountVisible ? 'RM ****' : 'RM ${widget.cycle?.openingBalance ?? '0.00'}'}',
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
                top: 4,
                right: 4,
                child: IconButton(
                  iconSize: 20,
                  onPressed: () {
                    setState(() {
                      _isAmountVisible = !_isAmountVisible;
                    });
                  },
                  icon: Icon(
                    _isAmountVisible ? Icons.visibility : Icons.visibility_off,
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
                onTap: widget.cycle != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransactionListPage(
                              cycle: widget.cycle!,
                              type: 'received',
                            ),
                          ),
                        );
                      }
                    : null,
                child: Card(
                  elevation: 3,
                  margin: const EdgeInsets.fromLTRB(8, 0, 8, 16),
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
                              : 'RM ${widget.cycle?.amountReceived ?? '0.00'}',
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
                onTap: widget.cycle != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransactionListPage(
                              cycle: widget.cycle!,
                              type: 'spent',
                            ),
                          ),
                        );
                      }
                    : null,
                child: Card(
                  elevation: 3,
                  margin: const EdgeInsets.fromLTRB(8, 0, 8, 16),
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
                              : 'RM ${widget.cycle?.amountSpent ?? '0.00'}',
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
