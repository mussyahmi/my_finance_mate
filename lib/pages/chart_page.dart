import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/cycle.dart';
import '../size_config.dart';
import 'transaction_list_page.dart';

class ChartPage extends StatefulWidget {
  final Cycle cycle;

  const ChartPage({super.key, required this.cycle});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  int totalTransaction = 0;
  double needsTotal = 0;
  double wantsTotal = 0;
  double savingsTotal = 0;
  double othersTotal = 0;
  double needsPercentage = 0;
  double wantsPercentage = 0;
  double savingsPercentage = 0;
  double othersPercentage = 0;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where the user is not authenticated.
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final transactionsRef = userRef.collection('transactions');

    final transactionQuery = await transactionsRef
        .where('deleted_at', isNull: true)
        .where('date_time', isGreaterThanOrEqualTo: widget.cycle.startDate)
        .where('date_time', isLessThanOrEqualTo: widget.cycle.endDate)
        .orderBy('date_time',
            descending: true) //* Sort by dateTime in descending order
        .get();

    double spentTotal = double.parse(widget.cycle.amountSpent);
    double needs = 0;
    double wants = 0;
    double savings = 0;
    double others = 0;

    for (var doc in transactionQuery.docs) {
      final data = doc.data();
      final amount = double.parse(data['amount']);

      if (data['type'] == 'spent') {
        if (data['subType'] == 'needs') {
          needs += amount;
        } else if (data['subType'] == 'wants') {
          wants += amount;
        } else if (data['subType'] == 'savings') {
          savings += amount;
        } else {
          others += amount;
        }
      }
    }

    setState(() {
      totalTransaction = transactionQuery.docs.length;
      needsPercentage = needs / spentTotal * 100;
      wantsPercentage = wants / spentTotal * 100;
      savingsPercentage = savings / spentTotal * 100;
      othersPercentage = others / spentTotal * 100;
      needsTotal = needs;
      wantsTotal = wants;
      savingsTotal = savings;
      othersTotal = others;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const SliverAppBar(
            title: Text('Subtype Chart'),
            centerTitle: true,
            scrolledUnderElevation: 9999,
            floating: true,
            snap: true,
          ),
        ],
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: SizeConfig.screenHeight! * 1 / 2,
                  child: _isLoading
                      ? const Center(child: Text('Loading...'))
                      : PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (p0, p1) {
                                if (p1 != null) {
                                  switch (
                                      p1.touchedSection!.touchedSectionIndex) {
                                    case 0:
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TransactionListPage(
                                            cycle: widget.cycle,
                                            subType: 'needs',
                                          ),
                                        ),
                                      );
                                    case 1:
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TransactionListPage(
                                            cycle: widget.cycle,
                                            subType: 'wants',
                                          ),
                                        ),
                                      );
                                    case 2:
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TransactionListPage(
                                            cycle: widget.cycle,
                                            subType: 'savings',
                                          ),
                                        ),
                                      );
                                    case 3:
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              TransactionListPage(
                                            cycle: widget.cycle,
                                            subType: 'others',
                                          ),
                                        ),
                                      );
                                  }
                                }
                              },
                            ),
                            sections: [
                              _pieChartSectionData(
                                Colors.green,
                                needsPercentage,
                                'Needs',
                              ),
                              _pieChartSectionData(
                                Colors.blue,
                                wantsPercentage,
                                'Wants',
                              ),
                              _pieChartSectionData(
                                Colors.yellow,
                                savingsPercentage,
                                'Savings',
                              ),
                              _pieChartSectionData(
                                Colors.grey,
                                othersPercentage,
                                'Others',
                              ),
                            ],
                            sectionsSpace: 3,
                            centerSpaceRadius: 0,
                          ),
                        ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: ListTile(
                        title: Text(
                          'Total of $totalTransaction transaction${totalTransaction > 0 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    _card('needs', needsTotal),
                    _card('wants', wantsTotal),
                    _card('savings', savingsTotal),
                    _card('others', othersTotal),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PieChartSectionData _pieChartSectionData(
      Color color, double percentage, String title) {
    return PieChartSectionData(
      color: color,
      value: percentage,
      radius: 100,
      title: title,
      titlePositionPercentageOffset: 1.3,
      badgeWidget: Text(
        '${percentage.toStringAsFixed(2)}%',
      ),
    );
  }

  Card _card(String subtype, double amount) {
    return Card(
      child: ListTile(
          title: Text('Total $subtype'),
          trailing: Text(
            'RM${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionListPage(
                  cycle: widget.cycle,
                  subType: subtype,
                ),
              ),
            );
          }),
    );
  }
}
