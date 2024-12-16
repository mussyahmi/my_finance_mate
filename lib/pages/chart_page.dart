// ignore_for_file: avoid_print

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../models/cycle.dart';
import '../models/transaction.dart' as t;
import '../providers/cycle_provider.dart';
import '../providers/person_provider.dart';
import '../providers/transactions_provider.dart';
import '../services/ad_mob_service.dart';
import '../size_config.dart';
import '../widgets/ad_container.dart';
import 'transaction_list_page.dart';
import '../extensions/string_extension.dart';
import '../widgets/custom_draggable_scrollable_sheet.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

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
  late AdMobService _adMobService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adMobService = context.read<AdMobService>();
    _calculateTransactions(context);
  }

  Future<void> _calculateTransactions(BuildContext context) async {
    Cycle cycle = context.read<CycleProvider>().cycle!;
    List<t.Transaction> transactions =
        context.read<TransactionsProvider>().transactions!;

    setState(() {
      _isLoading = true;
    });

    double spentTotal = double.parse(cycle.amountSpent);
    double needs = 0;
    double wants = 0;
    double savings = 0;
    double others = 0;

    for (var transaction in transactions) {
      final amount = double.parse(transaction.amount);

      if (transaction.type == 'spent') {
        if (transaction.subType == 'needs') {
          needs += amount;
        } else if (transaction.subType == 'wants') {
          wants += amount;
        } else if (transaction.subType == 'savings') {
          savings += amount;
        } else {
          others += amount;
        }
      }
    }

    setState(() {
      totalTransaction = transactions.length;
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
          SliverAppBar(
            title: const Text('Chart'),
            centerTitle: true,
            scrolledUnderElevation: 9999,
            floating: true,
            snap: true,
            actions: [
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return const CustomDraggableScrollableSheet(
                        initialSize: 0.4,
                        title: Column(
                          children: [
                            Text(
                              'Recommendations',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            SizedBox(height: 10),
                          ],
                        ),
                        contents: Column(
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                  '1. Needs (50%), Wants (30%), Savings (20%)'),
                            ),
                            SizedBox(height: 5),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                  '2. Needs (60%), Wants (30%), Savings (10%)'),
                            ),
                            SizedBox(height: 5),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                  '3. Needs (70%), Wants (20%), Savings (10%)'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(CupertinoIcons.info_circle_fill),
              ),
            ],
          ),
        ],
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 3,
                  child: ListTile(
                    dense: true,
                    title: Text(
                      'Total of $totalTransaction transaction${totalTransaction > 0 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(
                  height: SizeConfig.screenHeight! * 1 / 2,
                  child: _isLoading
                      ? const Center(child: Text('Loading...'))
                      : PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (p0, p1) {
                                if (p1 != null) {
                                  switch (p1
                                      .touchedSection!.touchedSection!.title) {
                                    case 'Needs':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const TransactionListPage(
                                            subType: 'needs',
                                          ),
                                        ),
                                      );
                                    case 'Wants':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const TransactionListPage(
                                            subType: 'wants',
                                          ),
                                        ),
                                      );
                                    case 'Savings':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const TransactionListPage(
                                            subType: 'savings',
                                          ),
                                        ),
                                      );
                                    case 'Others':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const TransactionListPage(
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
                                Colors.green[900]!,
                                needsPercentage,
                                'Needs',
                              ),
                              _pieChartSectionData(
                                Colors.blue[900]!,
                                wantsPercentage,
                                'Wants',
                              ),
                              _pieChartSectionData(
                                Colors.yellow[900]!,
                                savingsPercentage,
                                'Savings',
                              ),
                              _pieChartSectionData(
                                Colors.blueGrey[900]!,
                                othersPercentage,
                                'Others',
                              ),
                            ],
                            sectionsSpace: 3,
                            centerSpaceRadius: 0,
                          ),
                        ),
                ),
                if (!context.read<PersonProvider>().user!.isPremium)
                  Column(
                    children: [
                      AdContainer(
                        adMobService: _adMobService,
                        adSize: AdSize.largeBanner,
                        adUnitId: _adMobService.bannerChartAdUnitId!,
                        height: 100.0,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                _card('needs', needsPercentage, needsTotal),
                _card('wants', wantsPercentage, wantsTotal),
                _card('savings', savingsPercentage, savingsTotal),
                if (othersTotal > 0)
                  _card('others', othersPercentage, othersTotal),
                const SizedBox(height: 20),
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
    );
  }

  Card _card(String subtype, double percentage, double amount) {
    return Card(
      child: ListTile(
          dense: true,
          title: Text('Total ${subtype.capitalize()}'),
          subtitle: Text(
            'Percentage: ${percentage.toStringAsFixed(2)}%',
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
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
                  subType: subtype,
                ),
              ),
            );
          }),
    );
  }
}
