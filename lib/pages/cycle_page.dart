// ignore_for_file: use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cycle.dart';
import '../models/person.dart';
import '../providers/cycle_provider.dart';
import '../providers/cycles_provider.dart';
import '../providers/person_provider.dart';
import '../services/ad_cache_service.dart';
import '../services/ad_mob_service.dart';
import '../widgets/ad_container.dart';
import '../widgets/cycle_summary.dart';
import 'cycle_add_page.dart';
import 'cycle_list_page.dart';
import 'premium_access_page.dart';

class CyclePage extends StatefulWidget {
  const CyclePage({super.key});

  @override
  State<CyclePage> createState() => _CyclePageState();
}

class _CyclePageState extends State<CyclePage> {
  late SharedPreferences prefs;
  late AdMobService _adMobService;
  late AdCacheService _adCacheService;
  RewardedAd? _rewardedAd;
  int switchBetweenCycles = 0;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _adMobService = context.read<AdMobService>();
    _adCacheService = context.read<AdCacheService>();

    final Person user = context.read<PersonProvider>().user!;

    if (!user.isPremium) {
      _createRewardedAd();
    }
  }

  Future<void> initAsync() async {
    SharedPreferences? sharedPreferences =
        await SharedPreferences.getInstance();
    final savedCSiwtchBetweenCycles =
        sharedPreferences.getInt('switch_between_cycles');

    setState(() {
      prefs = sharedPreferences;
      switchBetweenCycles = savedCSiwtchBetweenCycles ?? 0;
    });
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Person user = context.watch<PersonProvider>().user!;
    Cycle cycle = context.watch<CycleProvider>().cycle!;

    Card card(String title) {
      var data = '';

      if (title == 'Cycle ID') {
        data = cycle.id;
      } else if (title == 'Cycle Name') {
        data = cycle.cycleName;
      } else if (title == 'Start Date') {
        data = DateFormat('EE, d MMM yyyy h:mm aa').format(cycle.startDate);
      } else if (title == 'End Date') {
        data = DateFormat('EE, d MMM yyyy h:mm aa').format(cycle.endDate);
      }

      return Card(
        child: ListTile(
          dense: true,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            data,
            style: const TextStyle(fontSize: 14),
          ),
          trailing:
              title != 'Cycle ID' && title != 'Start Date' && cycle.isLastCycle
                  ? IconButton.filledTonal(
                      onPressed: () async {
                        await cycle.showCycleDialog(
                          context,
                          user,
                          title,
                        );
                      },
                      icon: Icon(
                        CupertinoIcons.pencil,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : title == 'Cycle ID'
                      ? IconButton.filledTonal(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: data));

                            EasyLoading.showSuccess('Copied to clipboard');
                          },
                          icon: Icon(
                            Icons.copy,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : null,
        ),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const SliverAppBar(
            title: Text('Cycle'),
            centerTitle: true,
            scrolledUnderElevation: 9999,
            floating: true,
            snap: true,
          ),
        ],
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    const CycleSummary(),
                    const SizedBox(height: 20),
                    if (!user.isPremium)
                      Column(
                        children: [
                          AdContainer(
                            adCacheService: _adCacheService,
                            number: 1,
                            adSize: AdSize.mediumRectangle,
                            adUnitId: _adMobService.bannerCycleAdUnitId!,
                            height: 250.0,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    card('Cycle ID'),
                    card('Cycle Name'),
                    card('Start Date'),
                    card('End Date'),
                    if (cycle.endDate.isBefore(DateTime.now()))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 10.0, left: 20.0, right: 20.0),
                            child: ElevatedButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          CycleAddPage(cycle: cycle)),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                              ),
                              child: const Text("Start New Cycle"),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Past Cycle List',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          if (context.watch<CyclesProvider>().cycles != null)
                            TextButton(
                                onPressed: () async {
                                  final bool refreshSwitchBetweenCycles =
                                      await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CycleListPage(
                                        user: user,
                                        cycle: cycle,
                                      ),
                                    ),
                                  );

                                  if (refreshSwitchBetweenCycles) {
                                    final savedCSiwtchBetweenCycles =
                                        prefs.getInt('switch_between_cycles');

                                    setState(() {
                                      switchBetweenCycles =
                                          savedCSiwtchBetweenCycles ?? 0;
                                    });
                                  }
                                },
                                child: const Text('See all'))
                        ],
                      ),
                    ),
                    if (!user.isPremium && switchBetweenCycles > 0)
                      Column(
                        children: [
                          Text(
                            'You have $switchBetweenCycles switch${switchBetweenCycles > 1 ? 'es' : ''} remaining',
                            style: TextStyle(
                              color: Colors.orangeAccent,
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      )
                  ],
                ),
              ),
              FutureBuilder(
                future:
                    context.watch<CyclesProvider>().getLatestCycles(context),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: CircularProgressIndicator(),
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
                        'No cycles found.',
                        textAlign: TextAlign.center,
                      ),
                    ); //* Display a message for no cycles
                  } else {
                    //* Display the list of cycles
                    final cycles = snapshot.data!;
                    return Column(
                      children: cycles.asMap().entries.map<Widget>((entry) {
                        int index = entry.key;
                        Cycle c = entry.value as Cycle;

                        return Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Card(
                                child: ListTile(
                                  title: Text(
                                    c.cycleName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Received RM${c.amountReceived}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Spent RM${c.amountSpent}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: cycle.cycleNo != c.cycleNo
                                      ? IconButton.filledTonal(
                                          onPressed: () async {
                                            if (!user.isPremium &&
                                                switchBetweenCycles == 0 &&
                                                c.id !=
                                                    (cycles.first as Cycle)
                                                        .id) {
                                              return showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: const Text(
                                                        'Explore Cycle Switching!'),
                                                    content: const Text(
                                                        'Want to switch between cycles? You can try it up to 3 times by watching a quick ad, or unlock unlimited access by upgrading to Premium!'),
                                                    actions: [
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                          foregroundColor:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onPrimary,
                                                        ),
                                                        onPressed: () {
                                                          if (!user.isPremium) {
                                                            _showRewardedAd();
                                                          }

                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child: const Text(
                                                            'Watch Ad'),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          surfaceTintColor:
                                                              Colors.orange,
                                                          foregroundColor:
                                                              Colors
                                                                  .orangeAccent,
                                                        ),
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) =>
                                                                  const PremiumSubscriptionPage(),
                                                            ),
                                                          );
                                                        },
                                                        child: const Text(
                                                            'Upgrade to Premium'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child:
                                                            const Text('Later'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            }

                                            EasyLoading.show(
                                              dismissOnTap: false,
                                              status:
                                                  'Switching to the selected cycle...',
                                            );

                                            await context
                                                .read<CycleProvider>()
                                                .switchCycle(context, c);

                                            final bool
                                                updateSwitchBetweenCycles =
                                                !user.isPremium &&
                                                    switchBetweenCycles != 0 &&
                                                    c.id !=
                                                        (cycles.first as Cycle)
                                                            .id;

                                            if (updateSwitchBetweenCycles) {
                                              await prefs.setInt(
                                                  'switch_between_cycles',
                                                  switchBetweenCycles - 1);

                                              setState(() {
                                                switchBetweenCycles =
                                                    switchBetweenCycles - 1;
                                              });
                                            }

                                            EasyLoading.showInfo(
                                                'Cycle switched successfully!');
                                          },
                                          icon: Icon(
                                            CupertinoIcons.repeat,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            if (!user.isPremium &&
                                (index == 1 || index == 7 || index == 13))
                              AdContainer(
                                adCacheService: _adCacheService,
                                number: index,
                                adSize: AdSize.banner,
                                adUnitId:
                                    _adMobService.bannerCycleLatestAdUnitId!,
                                height: 50.0,
                              ),
                            if (index == cycles.length - 1)
                              const SizedBox(height: 20),
                          ],
                        );
                      }).toList(),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _createRewardedAd() {
    RewardedAd.load(
      adUnitId: _adMobService.rewardedSwitchBetweenCyclesAdUnitId!,
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
          EasyLoading.showInfo('Failed to show ad. Please try again later.');
          ad.dispose();
          _createRewardedAd();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) async {
          await prefs.setInt('switch_between_cycles', 3);

          setState(() {
            switchBetweenCycles = 3;
          });

          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Reward Granted!'),
                content: const Text(
                    'You\'re good to go! Choose any cycle you like to switch and take charge of your expenses! 🚀'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }
}
