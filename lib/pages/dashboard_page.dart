// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/cycle.dart';
import '../models/person.dart';
import '../services/ad_mob_service.dart';
import '../size_config.dart';
import '../widgets/cycle_summary.dart';
import '../widgets/forecast_budget.dart';
import 'category_list_page.dart';
import 'transaction_form_page.dart';
import 'explore_page.dart';
import '../models/transaction.dart' as t;
import 'transaction_list_page.dart';
import 'wishlist_page.dart';
import 'cycle_page.dart';

class DashboardPage extends StatefulWidget {
  final Person user;

  const DashboardPage({super.key, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  int selectedIndex = 0;
  Person? person;
  Cycle? cycle;
  bool _isLoading = false;
  bool _isPaused = false;

  //* Ad related
  late AdMobService _adMobService;
  BannerAd? _bannerAd;
  AppOpenAd? _appOpenAd;
  RewardedAd? _rewardedAd;

  @override
  void initState() {
    super.initState();

    //* Call the function when the DashboardPage is loaded
    _refreshPage();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

  Future<void> _refreshPage() async {
    setState(() {
      _isLoading = true;
    });
    cycle = await Cycle.fetchCycle(context, widget.user);
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    //* Initialize SizeConfig
    SizeConfig().init(context);

    return Scaffold(
      body: [
        NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              title: Text(cycle?.cycleName ?? 'Dashboard'),
              centerTitle: true,
              scrolledUnderElevation: 9999,
              floating: true,
              snap: true,
              actions: [
                IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CyclePage(
                            user: widget.user,
                            cycle: cycle,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_calendar))
              ],
            ),
          ],
          body: RefreshIndicator(
            onRefresh: _refreshPage,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: CycleSummary(user: widget.user, cycle: cycle),
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
                  ForecastBudget(
                    isLoading: _isLoading,
                    user: widget.user,
                    cycle: cycle,
                    onCategoryChanged: _refreshPage,
                  ),
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
                                  builder: (context) => TransactionListPage(
                                      user: widget.user, cycle: cycle!),
                                ),
                              );
                            },
                            child: const Text('View All'))
                      ],
                    ),
                  ),
                  FutureBuilder<List<t.Transaction>>(
                    future: t.Transaction.fetchTransactions(widget.user, 10),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting ||
                          _isLoading) {
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
                          children: transactions.map<Widget>((transaction) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Card(
                                child: ListTile(
                                  title: Text(
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
                                        DateFormat('EE, d MMM yyyy h:mm aa')
                                            .format(transaction.dateTime),
                                        style: const TextStyle(fontSize: 14),
                                      ),
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
                                        color: transaction.type == 'spent'
                                            ? Colors.red
                                            : Colors.green),
                                  ),
                                  onTap: () {
                                    //* Show the transaction summary dialog when tapped
                                    transaction.showTransactionDetails(
                                        context, widget.user, _refreshPage);
                                  },
                                ),
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
        const Center(
          child: Text('Coming Soon!'),
        ),
        cycle != null
            ? CategoryListPage(user: widget.user, cycle: cycle!)
            : Container(),
        WishlistPage(user: widget.user),
        ExplorePage(user: widget.user, cycle: cycle),
      ][selectedIndex],
      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                if (person!.dailyTransactionsMade >= 5) {
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
                              Navigator.of(context).pop(); //* Close the dialog
                            },
                            child: const Text('Close'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (_adMobService.status) _showRewardedAd();

                              Navigator.of(context).pop(); //* Close the dialog
                            },
                            child: const Text('Watch Ads'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  bool result = false;

                  result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TransactionFormPage(
                          user: widget.user, cycle: cycle!, action: 'Add'),
                    ),
                  );

                  if (result) {
                    await _refreshPage();
                  }
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.wallet), label: 'Account List'),
          NavigationDestination(
              icon: Icon(Icons.category), label: 'Category List'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Wishlist'),
          NavigationDestination(icon: Icon(Icons.explore), label: 'Explore'),
        ],
        onDestinationSelected: (value) {
          setState(() {
            selectedIndex = value;
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
        orientation: AppOpenAd.orientationPortrait);
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
          await Person.resetTransactionMade(person!.uid);

          await _refreshPage();
        },
      );
    }
  }
}
