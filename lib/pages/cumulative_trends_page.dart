import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/cycle.dart';
import '../models/transaction.dart' as t;
import '../providers/cycle_provider.dart';
import '../providers/transactions_provider.dart';

class CumulativeTrendsPage extends StatefulWidget {
  const CumulativeTrendsPage({
    super.key,
  });

  @override
  State<CumulativeTrendsPage> createState() => _CumulativeTrendsPageState();
}

class _CumulativeTrendsPageState extends State<CumulativeTrendsPage> {
  List<t.Transaction> _transactions = [];
  List<t.Transaction> _filteredTransactions = [];
  List<FlSpot> _spentSpots = [];
  List<FlSpot> _receivedSpots = [];
  bool _isLoading = true;
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    await generateCumulativeSpots();
  }

  Future<void> generateCumulativeSpots() async {
    double spentCumulativeSum = 0;
    double receivedCumulativeSum = 0;

    Map<double, double> spentMap = {};
    Map<double, double> receivedMap = {};

    List<t.Transaction> transactions =
        context.read<TransactionsProvider>().transactions!.reversed.toList();

    if (transactions.isEmpty) return;

    DateTime startDate = transactions.first.dateTime;

    for (var transaction in transactions) {
      double amount = double.tryParse(transaction.amount) ?? 0;
      DateTime transactionDate = transaction.dateTime;
      double xValue = transactionDate.difference(startDate).inDays.toDouble();

      if (transaction.type == 'spent') {
        spentCumulativeSum += amount;
        spentMap[xValue] = double.parse(spentCumulativeSum.toStringAsFixed(2));
      } else if (transaction.type == 'received') {
        receivedCumulativeSum += amount;
        receivedMap[xValue] =
            double.parse(receivedCumulativeSum.toStringAsFixed(2));
      }
    }

    setState(() {
      _transactions = transactions;
      _spentSpots =
          spentMap.entries.map((e) => FlSpot(e.key, e.value)).toList();
      _receivedSpots =
          receivedMap.entries.map((e) => FlSpot(e.key, e.value)).toList();
      _isLoading = false;
      _startDate = startDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    Cycle cycle = context.read<CycleProvider>().cycle!;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const SliverAppBar(
            title: Text('Cumulative Trends'),
            centerTitle: true,
            scrolledUnderElevation: 9999,
            floating: true,
            snap: true,
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Press the chart to see the list of transactions for a specific day.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.touch_app, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Text(
                                  'Tap on a point to view details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Received'),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Spent'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 350,
                        margin: EdgeInsets.only(bottom: 16, left: 32),
                        child: LineChart(
                          LineChartData(
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text('RM${meta.formattedValue}'),
                                    );
                                  },
                                  reservedSize: 60,
                                  minIncluded: false,
                                  maxIncluded: false,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Transform.rotate(
                                        angle: -0.5,
                                        child: Text(
                                          DateFormat('d MMM')
                                              .format(_startDate.add(
                                            Duration(days: value.toInt()),
                                          )),
                                        ),
                                      ),
                                    );
                                  },
                                  reservedSize: 60,
                                  interval: 3,
                                  minIncluded: false,
                                  maxIncluded: false,
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _spentSpots,
                                color: Colors.red,
                                barWidth: 4,
                                isCurved: true,
                                isStrokeCapRound: true,
                                belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.red.withAlpha(77)),
                              ),
                              LineChartBarData(
                                spots: _receivedSpots,
                                color: Colors.green,
                                barWidth: 4,
                                isCurved: true,
                                isStrokeCapRound: true,
                                belowBarData: BarAreaData(
                                    show: true,
                                    color: Colors.green.withAlpha(77)),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              touchCallback: (p0, p1) {
                                if (p1 == null) return;

                                p1.lineBarSpots?.forEach((element) {
                                  DateTime xDate = _startDate
                                      .add(Duration(days: element.x.toInt()));

                                  setState(() {
                                    _filteredTransactions = _transactions
                                        .where((transaction) =>
                                            transaction.dateTime.year ==
                                                xDate.year &&
                                            transaction.dateTime.month ==
                                                xDate.month &&
                                            transaction.dateTime.day ==
                                                xDate.day)
                                        .toList();
                                  });
                                });
                              },
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((touchedSpot) {
                                    return LineTooltipItem(
                                      'RM${touchedSpot.y}',
                                      TextStyle(
                                          color: touchedSpot.bar.color,
                                          fontWeight: FontWeight.bold),
                                    );
                                  }).toList();
                                },
                                showOnTopOfTheChartBoxArea: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_filteredTransactions.isNotEmpty)
                        Column(
                          children: _filteredTransactions
                              .asMap()
                              .entries
                              .map<Widget>((entry) {
                            int index = entry.key;
                            t.Transaction transaction = entry.value;

                            late t.Transaction prevTransaction;

                            if (index > 0) {
                              prevTransaction =
                                  _filteredTransactions[index - 1];
                            }

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Column(
                                    children: [
                                      if (index == 0 ||
                                          DateTime(
                                                  transaction.dateTime.year,
                                                  transaction.dateTime.month,
                                                  transaction.dateTime.day,
                                                  0,
                                                  0) !=
                                              DateTime(
                                                  prevTransaction.dateTime.year,
                                                  prevTransaction
                                                      .dateTime.month,
                                                  prevTransaction.dateTime.day,
                                                  0,
                                                  0))
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            transaction.getDateText(),
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey),
                                          ),
                                        ),
                                      Card(
                                        child: ListTile(
                                          title: transaction.type == 'transfer'
                                              ? Row(
                                                  children: [
                                                    Chip(
                                                      label: Text(
                                                        transaction.accountName,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      padding:
                                                          EdgeInsets.all(0),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8.0),
                                                      child: Icon(
                                                          CupertinoIcons
                                                              .arrow_right_arrow_left,
                                                          color: Colors.grey),
                                                    ),
                                                    Chip(
                                                      label: Text(
                                                        transaction
                                                            .accountToName,
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      padding:
                                                          EdgeInsets.all(0),
                                                    ),
                                                  ],
                                                )
                                              : FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    transaction.categoryName,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16),
                                                  ),
                                                ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                transaction.note
                                                        .contains('insert')
                                                    ? ParchmentDocument
                                                            .fromJson(
                                                                jsonDecode(
                                                                    transaction
                                                                        .note))
                                                        .toPlainText()
                                                    : transaction.note
                                                        .split('\\n')[0],
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontStyle: FontStyle.italic,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                          trailing: Text(
                                            '${transaction.type == 'spent' ? '-' : ''}RM${transaction.amount}',
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: transaction.type ==
                                                        'transfer'
                                                    ? Colors.grey
                                                    : transaction.type ==
                                                            'spent'
                                                        ? Colors.red
                                                        : Colors.green),
                                          ),
                                          onTap: () {
                                            //* Show the transaction summary dialog when tapped
                                            transaction.showTransactionDetails(
                                                context, cycle);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // if (!user.isPremium &&
                                //     (index == 1 || index == 7 || index == 13))
                                //   AdContainer(
                                //     adCacheService: _adCacheService,
                                //     number: index,
                                //     adSize: AdSize.banner,
                                //     adUnitId: _adMobService!
                                //         .bannerTransactionLatestAdUnitId!,
                                //     height: 50.0,
                                //   )
                              ],
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
