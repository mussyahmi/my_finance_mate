// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import '../models/account.dart';
import '../models/category.dart';
import '../models/cycle.dart';
import '../models/person.dart';
import '../providers/accounts_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/cycle_provider.dart';
import '../providers/transactions_provider.dart';
import '../providers/person_provider.dart';
import '../services/ad_mob_service.dart';
import '../size_config.dart';
import '../widgets/ad_container.dart';
import '../widgets/cycle_summary.dart';
import '../widgets/forecast_budget.dart';
import 'account_list_page.dart';
import 'category_list_page.dart';
import 'profile_page.dart';
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
  String _categoryType = 'spent';
  AdMobService? _adMobService;
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

    final bool forceRefresh = context.read<PersonProvider>().user!.forceRefresh;

    if (forceRefresh || context.read<CycleProvider>().cycle == null) {
      await context
          .read<CycleProvider>()
          .fetchCycle(context, refresh: forceRefresh);
    }

    if (forceRefresh || context.read<CycleProvider>().cycle != null) {
      if (forceRefresh ||
          context.read<CategoriesProvider>().categories == null) {
        await context.read<CategoriesProvider>().fetchCategories(
            context, context.read<CycleProvider>().cycle!,
            refresh: forceRefresh);
      }

      if (forceRefresh || context.read<AccountsProvider>().accounts == null) {
        await context.read<AccountsProvider>().fetchAccounts(
            context, context.read<CycleProvider>().cycle!,
            refresh: forceRefresh);
      }

      if (forceRefresh ||
          context.read<TransactionsProvider>().transactions == null) {
        await context.read<TransactionsProvider>().fetchTransactions(
            context, context.read<CycleProvider>().cycle!,
            refresh: forceRefresh);
      }

      if (forceRefresh) {
        await context.read<PersonProvider>().resetForceRefresh();
      }
    }

    _adMobService = context.read<AdMobService>();

    if (_adMobService!.status) {
      _createAppOpenAd();
      _createRewardedAd();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? pauseCounter = prefs.getInt('pause_counter');

    if (pauseCounter == null) {
      await prefs.setInt('pause_counter', 0);
      pauseCounter = 0;
    }

    if (state == AppLifecycleState.paused) {
      await prefs.setInt('pause_counter', pauseCounter + 1);
      print('Paused');
    } else if (state == AppLifecycleState.resumed && pauseCounter >= 3) {
      if (_adMobService!.status) _showAppOpenAd(prefs);
      print('Resumed');
    }

    print('Pause counter: $pauseCounter');
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void changeCategoryType(String type) {
    _categoryType = type;
  }

  @override
  Widget build(BuildContext context) {
    Person user = context.watch<PersonProvider>().user!;
    Cycle? cycle = context.watch<CycleProvider>().cycle;

    //* Initialize SizeConfig
    SizeConfig().init(context);

    return UpgradeAlert(
      child: Scaffold(
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
                    const SizedBox(height: 20),
                    if (_adMobService != null && _adMobService!.status)
                      Column(
                        children: [
                          AdContainer(
                            adMobService: _adMobService!,
                            adSize: AdSize.mediumRectangle,
                            adUnitId: _adMobService!.bannerDasboardAdUnitId!,
                            height: 250.0,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
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
                    FutureBuilder(
                      future: context
                          .watch<TransactionsProvider>()
                          .getLatestTransactions(context),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                                ConnectionState.waiting ||
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
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
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
                            children: transactions
                                .asMap()
                                .entries
                                .map<Widget>((entry) {
                              int index = entry.key;
                              t.Transaction transaction =
                                  entry.value as t.Transaction;

                              late t.Transaction prevTransaction;

                              if (index > 0) {
                                if (transactions[index - 1] is t.Transaction) {
                                  prevTransaction =
                                      transactions[index - 1] as t.Transaction;
                                } else {
                                  prevTransaction =
                                      transactions[index - 2] as t.Transaction;
                                }
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
                                                    prevTransaction
                                                        .dateTime.year,
                                                    prevTransaction
                                                        .dateTime.month,
                                                    prevTransaction
                                                        .dateTime.day,
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
                                            title: transaction.type ==
                                                    'transfer'
                                                ? Row(
                                                    children: [
                                                      Chip(
                                                        label: Text(
                                                          transaction
                                                              .accountName,
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        padding:
                                                            EdgeInsets.all(0),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                    4.0),
                                                        child: Icon(
                                                            Icons.arrow_forward,
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
                                                : Text(
                                                    transaction.categoryName,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16),
                                                  ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  transaction.note
                                                      .split('\\n')[0],
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      fontStyle:
                                                          FontStyle.italic,
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
                                              transaction
                                                  .showTransactionDetails(
                                                      context, cycle);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_adMobService!.status &&
                                      (index == 1 || index == 7 || index == 13))
                                    AdContainer(
                                      adMobService: _adMobService!,
                                      adSize: AdSize.fullBanner,
                                      adUnitId: _adMobService!
                                          .bannerTransactionLatestAdUnitId!,
                                      height: 60.0,
                                    )
                                ],
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
          cycle != null
              ? CategoryListPage(changeCategoryType: changeCategoryType)
              : Container(),
          cycle != null ? const ProfilePage() : Container(),
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
                                  if (_adMobService!.status) _showRewardedAd();

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
                    Category.showCategoryFormDialog(
                        context, _categoryType, 'Add');
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
            NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          ],
          onDestinationSelected: (value) {
            setState(() {
              _selectedIndex = value;
            });
          },
          elevation: 9999,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        ),
      ),
    );
  }

  void _createAppOpenAd() {
    AppOpenAd.load(
      adUnitId: _adMobService!.appOpenAdUnitId!,
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

  void _showAppOpenAd(SharedPreferences prefs) async {
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

      await _appOpenAd!.show();
      await prefs.setInt('pause_counter', 0);
      _appOpenAd = null;
    }
  }

  void _createRewardedAd() {
    RewardedAd.load(
      adUnitId: _adMobService!.rewardedAdUnitId!,
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
          await context.read<PersonProvider>().resetTransactionMade();
        },
      );
    }
  }
}
