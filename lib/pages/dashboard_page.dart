// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../models/account.dart';
import '../models/category.dart';
import '../models/cycle.dart';
import '../models/person.dart';
import '../providers/accounts_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/cycle_provider.dart';
import '../providers/transactions_provider.dart';
import '../providers/user_provider.dart';
import '../services/ad_mob_service.dart';
import '../size_config.dart';
import '../widgets/cycle_summary.dart';
import '../widgets/forecast_budget.dart';
import 'account_list_page.dart';
import 'category_list_page.dart';
import 'explore_page.dart';
import '../models/transaction.dart' as t;
import 'transaction_form_page.dart';
import 'transaction_list_page.dart';
import 'cycle_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isPaused = false;

  //* Ad related
  late AdMobService _adMobService;
  BannerAd? _bannerAd;
  AppOpenAd? _appOpenAd;
  RewardedAd? _rewardedAd;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    if (context.read<CycleProvider>().cycle == null) {
      await context.read<CycleProvider>().fetchCycle(context);
    }

    if (context.read<CycleProvider>().cycle != null) {
      if (context.read<CategoriesProvider>().categories == null) {
        await context
            .read<CategoriesProvider>()
            .fetchCategories(context, context.read<CycleProvider>().cycle!);
      }

      if (context.read<AccountsProvider>().accounts == null) {
        await context
            .read<AccountsProvider>()
            .fetchAccounts(context, context.read<CycleProvider>().cycle!);
      }

      if (context.read<TransactionsProvider>().transactions == null) {
        await context
            .read<TransactionsProvider>()
            .fetchTransactions(context, context.read<CycleProvider>().cycle!);
      }
    }

    //* Ads related
    _adMobService = context.read<AdMobService>();

    if (_adMobService.status) {
      _adMobService.initialization.then((value) {
        setState(() {
          _bannerAd = BannerAd(
            size: AdSize.mediumRectangle,
            adUnitId: _adMobService.bannerDasboardAdUnitId!,
            listener: _adMobService.bannerAdListener,
            request: const AdRequest(),
          )..load();
        });
      });

      _createAppOpenAd();
      _createRewardedAd();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      _isPaused = true;
      print('Paused');
    } else if (state == AppLifecycleState.resumed && _isPaused) {
      if (_adMobService.status) _showAppOpenAd();
      _isPaused = false;
      print('Resumed');
    }
  }

  @override
  void dispose() {
    super.dispose();

    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    EasyLoading.instance
      ..loadingStyle = EasyLoadingStyle.custom
      ..backgroundColor = Theme.of(context).colorScheme.secondary
      ..indicatorType = EasyLoadingIndicatorType.ripple
      ..indicatorColor = Theme.of(context).colorScheme.onSecondary
      ..textColor = Theme.of(context).colorScheme.onSecondary
      ..progressColor = Colors.blue
      ..maskColor = Colors.green.withOpacity(0.5)
      ..userInteractions = false
      ..dismissOnTap = false;

    Person user = context.watch<UserProvider>().user!;
    Cycle? cycle = context.watch<CycleProvider>().cycle;

    //* Initialize SizeConfig
    SizeConfig().init(context);

    return Scaffold(
      body: [
        NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              title: Text(cycle != null ? cycle.cycleName : 'Dashboard'),
              centerTitle: true,
              scrolledUnderElevation: 9999,
              floating: true,
              snap: true,
              actions: [
                if (cycle != null)
                  IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CyclePage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_calendar))
              ],
            ),
          ],
          body: RefreshIndicator(
            onRefresh: () async {
              if (cycle!.isLastCycle) {
                context
                    .read<CycleProvider>()
                    .fetchCycle(context, refresh: true);
                context
                    .read<CategoriesProvider>()
                    .fetchCategories(context, cycle, refresh: true);
                context
                    .read<AccountsProvider>()
                    .fetchAccounts(context, cycle, refresh: true);
                context
                    .read<TransactionsProvider>()
                    .fetchTransactions(context, cycle, refresh: true);
              }
            },
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: CycleSummary(),
                  ),
                  if (_bannerAd != null)
                    Column(
                      children: [
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 250.0,
                          child: AdWidget(ad: _bannerAd!),
                        ),
                      ],
                    ),
                  const SizedBox(height: 30),
                  const ForecastBudget(),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transaction List',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const TransactionListPage(),
                                ),
                              );
                            },
                            child: const Text('See all'))
                      ],
                    ),
                  ),
                  FutureBuilder<List<t.Transaction>>(
                    future: context
                        .watch<TransactionsProvider>()
                        .getLatestTransactions(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting ||
                          cycle == null) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                            ],
                          ),
                        ); //* Display a loading indicator
                      } else if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: SelectableText(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            'No transactions found.',
                            textAlign: TextAlign.center,
                          ),
                        ); //* Display a message for no transactions
                      } else {
                        //* Display the list of transactions
                        final transactions = snapshot.data!;
                        return Column(
                          children:
                              transactions.asMap().entries.map<Widget>((entry) {
                            int index = entry.key;
                            t.Transaction transaction = entry.value;

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
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
                                              transactions[index - 1]
                                                  .dateTime
                                                  .year,
                                              transactions[index - 1]
                                                  .dateTime
                                                  .month,
                                              transactions[index - 1]
                                                  .dateTime
                                                  .day,
                                              0,
                                              0))
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        transaction.getDateText(),
                                        style: const TextStyle(
                                            fontSize: 14, color: Colors.grey),
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
                                                  padding: EdgeInsets.all(0),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 4.0),
                                                  child: Icon(
                                                      Icons.arrow_forward,
                                                      color: Colors.grey),
                                                ),
                                                Chip(
                                                  label: Text(
                                                    transaction.accountToName,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  padding: EdgeInsets.all(0),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              transaction.categoryName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            transaction.note.split('\\n')[0],
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
                                                : transaction.type == 'spent'
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
                            );
                          }).toList(),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
        cycle != null ? const AccountListPage() : Container(),
        cycle != null ? const CategoryListPage() : Container(),
        cycle != null ? const ExplorePage() : Container(),
      ][_selectedIndex],
      floatingActionButton: _selectedIndex != 3 &&
              cycle != null &&
              cycle.isLastCycle
          ? FloatingActionButton(
              onPressed: () async {
                if (_selectedIndex == 0) {
                  if (context.read<AccountsProvider>().accounts!.isEmpty) {
                    EasyLoading.showInfo(
                        'No accounts? Let\'s fix that—add one to begin!');
                  } else if (user.dailyTransactionsMade >= 5) {
                    await showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Whoops!'),
                          content: const Text(
                              'You hit the daily transaction cap. Wanna reset it by checking out some ads?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context)
                                    .pop(); //* Close the dialog
                              },
                              child: const Text('Close'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (_adMobService.status) _showRewardedAd();

                                Navigator.of(context)
                                    .pop(); //* Close the dialog
                              },
                              child: const Text('Watch Ads'),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TransactionFormPage(action: 'Add'),
                      ),
                    );
                  }
                } else if (_selectedIndex == 1) {
                  Account.showAccountFormDialog(context, 'Add');
                } else if (_selectedIndex == 2) {
                  Category.showCategoryFormDialog(context, 'received', 'Add');
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.wallet), label: 'Account List'),
          NavigationDestination(
              icon: Icon(Icons.category), label: 'Category List'),
          NavigationDestination(icon: Icon(Icons.explore), label: 'Explore'),
        ],
        onDestinationSelected: (value) {
          setState(() {
            _selectedIndex = value;
          });
        },
        elevation: 9999,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
    );
  }

  void _createAppOpenAd() {
    AppOpenAd.load(
      adUnitId: _adMobService.appOpenAdUnitId!,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
        },
      ),
    );
  }

  void _showAppOpenAd() {
    if (_appOpenAd != null) {
      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _createAppOpenAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _createAppOpenAd();
        },
      );

      _appOpenAd!.show();
      _appOpenAd = null;
    }
  }

  void _createRewardedAd() {
    RewardedAd.load(
      adUnitId: _adMobService.rewardedAdUnitId!,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
          });
        },
        onAdFailedToLoad: (error) {
          setState(() {
            _rewardedAd = null;
          });
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _createRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _createRewardedAd();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) async {
          await context.read<UserProvider>().resetTransactionMade();
        },
      );
    }
  }
}
