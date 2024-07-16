// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/cycle.dart';
import '../models/person.dart';
import '../services/ad_mob_service.dart';
import '../size_config.dart';
import '../widgets/cycle_summary.dart';
import '../widgets/forecast_budget.dart';
import 'add_cycle_page.dart';
import 'category_list_page.dart';
import 'transaction_form_page.dart';
import 'explore_page.dart';
import '../models/transaction.dart' as t;
import 'transaction_list_page.dart';
import 'wishlist_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

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
    await _fetchCycle();
    await _fetchUser();
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
                    onPressed: () {}, icon: const Icon(Icons.edit_calendar))
              ],
            ),
          ],
          body: RefreshIndicator(
            onRefresh: _refreshPage,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CycleSummary(cycle: cycle),
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
                  const SizedBox(height: 20),
                  ForecastBudget(
                    isLoading: _isLoading,
                    cycle: cycle,
                    onCategoryChanged: _refreshPage,
                  ),
                  const SizedBox(height: 20),
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
                                      TransactionListPage(cycle: cycle!),
                                ),
                              );
                            },
                            child: const Text('View All'))
                      ],
                    ),
                  ),
                  FutureBuilder<List<t.Transaction>>(
                    future: _fetchTransactions(),
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
                        final transactions = snapshot.data;
                        return Container(
                          constraints: const BoxConstraints(
                            maxHeight: 300,
                          ),
                          height: min(300, transactions!.length * 120),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = transactions[index];
                              return Dismissible(
                                key: Key(transaction
                                    .id), //* Unique key for each transaction
                                background: Container(
                                  color: Colors
                                      .green, //* Background color for edit action
                                  alignment: Alignment.centerLeft,
                                  child: const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                secondaryBackground: Container(
                                  color: Colors
                                      .red, //* Background color for delete action
                                  alignment: Alignment.centerRight,
                                  child: const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction ==
                                      DismissDirection.startToEnd) {
                                    final transactionCycle =
                                        await transaction.cycle();

                                    //* Edit action
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TransactionFormPage(
                                          cycle: transactionCycle!,
                                          action: 'Edit',
                                          transaction: transaction,
                                        ),
                                      ),
                                    );

                                    if (result == true) {
                                      await _refreshPage();
                                      return true;
                                    } else {
                                      return false;
                                    }
                                  } else if (direction ==
                                      DismissDirection.endToStart) {
                                    //* Delete action
                                    final result = await transaction
                                        .deleteTransaction(context);

                                    if (result == true) {
                                      await _refreshPage();
                                      return true;
                                    } else {
                                      return false;
                                    }
                                  }

                                  return false;
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
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
                                            style:
                                                const TextStyle(fontSize: 14),
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
                                        transaction
                                            .showTransactionSummaryDialog(
                                                context);
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
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
        Container(),
        cycle != null ? CategoryListPage(cycle: cycle!) : Container(),
        const WishlistPage(),
        ExplorePage(cycle: cycle),
      ][selectedIndex],
      floatingActionButton: selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                if (person!.transactionsMade >= person!.transactionLimit) {
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
                      builder: (context) =>
                          TransactionFormPage(cycle: cycle!, action: 'Add'),
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

  Future<List<t.Transaction>> _fetchTransactions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where the user is not authenticated.
      return [];
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final transactionsRef = userRef.collection('transactions');

    final transactionQuery = await transactionsRef
        .where('deleted_at', isNull: true)
        .orderBy('date_time',
            descending: true) //* Sort by dateTime in descending order
        .limit(10) //* Limit to 10 items
        .get();

    final transactions = transactionQuery.docs.map((doc) async {
      final data = doc.data();

      //* Fetch the category name based on the categoryId
      DocumentSnapshot<Map<String, dynamic>> categoryDoc;
      categoryDoc = await userRef
          .collection('cycles')
          .doc(data['cycle_id'])
          .collection('categories')
          .doc(data['category_id'])
          .get();

      final categoryName = categoryDoc['name'] as String;

      //* Create a Transaction object with the category name
      return t.Transaction(
        id: doc.id,
        cycleId: data['cycle_id'],
        dateTime: (data['date_time'] as Timestamp).toDate(),
        type: data['type'] as String,
        subType: data['subType'],
        categoryId: data['category_id'],
        categoryName: categoryName,
        amount: data['amount'] as String,
        note: data['note'] as String,
        files: data['files'] != null ? data['files'] as List : [],
        //* Add other transaction properties as needed
      );
    }).toList();

    var result = await Future.wait(transactions);

    //* Sort the list by 'created_at' in ascending order (most recent first)
    result.sort((a, b) => (b.dateTime).compareTo(a.dateTime));

    return result;
  }

  Future<void> _fetchUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where user is not authenticated
      return;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    if (userDoc.exists) {
      final transactionsRef = userRef.collection('transactions');
      final transactionQuery = await transactionsRef
          .where('deleted_at', isNull: true)
          .orderBy('date_time',
              descending: true) //* Sort by dateTime in descending order
          .limit(1)
          .get();

      final lastTransaction = transactionQuery.docs.first;

      DateTime today = DateTime.now();
      DateTime lastTansactionDate =
          (lastTransaction['date_time'] as Timestamp).toDate();

      int transactionMade = userDoc['transactions_made'];

      if (!(lastTansactionDate.year == today.year &&
              lastTansactionDate.month == today.month &&
              lastTansactionDate.day == today.day) &&
          transactionMade > 0) {
        await Person.resetTransactionLimit(user.uid);

        transactionMade = 0;
      }

      person = Person(
        uid: userDoc.id,
        fullName: userDoc['full_name'] ?? '',
        nickname: userDoc['nickname'] ?? '',
        email: userDoc['email'],
        photoUrl: userDoc['photo_url'] ?? '',
        lastLogin: (userDoc['last_login'] as Timestamp).toDate(),
        transactionLimit: 5,
        transactionsMade: transactionMade,
      );
    }
  }

  Future<void> _fetchCycle() async {
    final DateTime currentDate = DateTime.now();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where user is not authenticated
      return;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final cyclesRef = userRef.collection('cycles');

    final lastCycleQuery =
        cyclesRef.orderBy('cycle_no', descending: true).limit(1);
    final lastCycleSnapshot = await lastCycleQuery.get();

    if (lastCycleSnapshot.docs.isNotEmpty) {
      final lastCycleDoc = lastCycleSnapshot.docs.first;

      Cycle lastCycle = Cycle(
        id: lastCycleDoc.id,
        cycleNo: lastCycleDoc['cycle_no'],
        cycleName: lastCycleDoc['cycle_name'],
        openingBalance: lastCycleDoc['opening_balance'],
        amountBalance: lastCycleDoc['amount_balance'],
        amountReceived: lastCycleDoc['amount_received'],
        amountSpent: lastCycleDoc['amount_spent'],
        startDate: (lastCycleDoc['start_date'] as Timestamp).toDate(),
        endDate: (lastCycleDoc['end_date'] as Timestamp).toDate(),
      );

      if (lastCycle.endDate.isBefore(currentDate)) {
        //* Last cycle has ended, redirect to add cycle page
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  AddCyclePage(isFirstCycle: false, lastCycle: lastCycle)),
        );
      }

      cycle = lastCycle;
    } else {
      //* No cycles found, redirect to add cycle page
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const AddCyclePage(isFirstCycle: true)),
      );
    }
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
          await Person.resetTransactionLimit(person!.uid);

          await _refreshPage();
        },
      );
    }
  }
}
