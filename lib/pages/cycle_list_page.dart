// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../models/cycle.dart';
import '../models/person.dart';
import '../providers/cycle_provider.dart';
import '../providers/cycles_provider.dart';
import '../providers/person_provider.dart';
import '../services/ad_mob_service.dart';
import '../widgets/ad_container.dart';

class CycleListPage extends StatefulWidget {
  final Person user;
  final Cycle? cycle;

  const CycleListPage({
    super.key,
    required this.user,
    required this.cycle,
  });

  @override
  State<CycleListPage> createState() => _CycleListPageState();
}

class _CycleListPageState extends State<CycleListPage> {
  late AdMobService _adMobService;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    _adMobService = context.read<AdMobService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const SliverAppBar(
            title: Text('Cycle List'),
            centerTitle: true,
            scrolledUnderElevation: 9999,
            floating: true,
            snap: true,
          ),
        ],
        body: Center(
          child: FutureBuilder(
            future: context.watch<CyclesProvider>().getCycles(context),
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
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: cycles.length,
                  itemBuilder: (context, index) {
                    Cycle c = cycles[index] as Cycle;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Card(
                            child: ListTile(
                              title: Text(
                                c.cycleName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                              trailing: widget.cycle!.cycleNo != c.cycleNo
                                  ? IconButton.filledTonal(
                                      onPressed: () async {
                                        if (!context
                                            .read<PersonProvider>()
                                            .user!
                                            .isPremium) {
                                          return EasyLoading.showInfo(
                                              'Upgrade to Premium to switch between cycles.');
                                        }

                                        EasyLoading.show(
                                            status:
                                                'Switching to the selected cycle...');

                                        await context
                                            .read<CycleProvider>()
                                            .switchCycle(context, c);

                                        EasyLoading.showInfo(
                                            'Cycle switched successfully!');

                                        Navigator.of(context).pop();
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
                        if (!context.read<PersonProvider>().user!.isPremium &&
                            (index == 1 || index == 7 || index == 13))
                          AdContainer(
                            adMobService: _adMobService,
                            adSize: AdSize.fullBanner,
                            adUnitId: _adMobService.bannerCycleListAdUnitId!,
                            height: 60.0,
                          ),
                        if (index == cycles.length - 1)
                          const SizedBox(height: 20),
                      ],
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
