import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/cycle.dart';
import '../models/person.dart';
import '../providers/cycle_provider.dart';
import '../providers/cycles_provider.dart';
import '../providers/user_provider.dart';
import '../services/ad_mob_service.dart';
import '../widgets/ad_container.dart';
import '../widgets/cycle_summary.dart';
import 'cycle_list_page.dart';

class CyclePage extends StatefulWidget {
  const CyclePage({super.key});

  @override
  State<CyclePage> createState() => _CyclePageState();
}

class _CyclePageState extends State<CyclePage> {
  late AdMobService _adMobService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (context.read<CyclesProvider>().cycles == null) {
      context.read<CyclesProvider>().fetchCycles(context);
    }

    _adMobService = context.read<AdMobService>();
  }

  @override
  Widget build(BuildContext context) {
    Person user = context.watch<UserProvider>().user!;
    Cycle cycle = context.watch<CycleProvider>().cycle!;

    Card card(String title) {
      var data = '';

      if (title == 'Cycle Name') {
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
          trailing: title != 'Start Date' && cycle.isLastCycle
              ? IconButton.filledTonal(
                  onPressed: () async {
                    await cycle.showCycleFormDialog(
                      context,
                      user,
                      cycle,
                      title,
                    );
                  },
                  icon: Icon(
                    Icons.edit,
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
        body: RefreshIndicator(
          onRefresh: () async {
            if (cycle.isLastCycle) {
              context.read<CycleProvider>().fetchCycle(context, refresh: true);
              context
                  .read<CyclesProvider>()
                  .fetchCycles(context, refresh: true);
            }
          },
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const CycleSummary(),
                      const SizedBox(height: 20),
                      if (_adMobService.status)
                        Column(
                          children: [
                            AdContainer(
                              adMobService: _adMobService,
                              adSize: AdSize.mediumRectangle,
                              adUnitId: _adMobService.bannerCycleAdUnitId!,
                              height: 250.0,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      card('Cycle Name'),
                      card('Start Date'),
                      card('End Date'),
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
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CycleListPage(
                                          user: user,
                                          cycle: cycle,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('See all'))
                          ],
                        ),
                      ),
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
                                              await context
                                                  .read<CycleProvider>()
                                                  .switchCycle(context, c);
                                            },
                                            icon: Icon(
                                              Icons.arrow_forward_ios,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              if (_adMobService.status &&
                                  (index == 1 || index == 7 || index == 13))
                                AdContainer(
                                  adMobService: _adMobService,
                                  adSize: AdSize.fullBanner,
                                  adUnitId:
                                      _adMobService.bannerCycleLatestAdUnitId!,
                                  height: 60.0,
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
      ),
    );
  }
}
