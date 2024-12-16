// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../models/cycle.dart';
import '../models/wishlist.dart';
import '../providers/cycle_provider.dart';
import '../providers/person_provider.dart';
import '../providers/wishlist_provider.dart';
import '../services/ad_cache_service.dart';
import '../services/ad_mob_service.dart';
import '../widgets/ad_container.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<Object> wishlist = [];
  late AdMobService _adMobService;
  late AdCacheService _adCacheService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (context.read<WishlistProvider>().wishlist == null) {
      context.read<WishlistProvider>().fetchWishlist(context);
    }

    _adMobService = context.read<AdMobService>();
    _adCacheService = context.read<AdCacheService>();
  }

  @override
  Widget build(BuildContext context) {
    Cycle cycle = context.watch<CycleProvider>().cycle!;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          const SliverAppBar(
            title: Text('Wishlist'),
            centerTitle: true,
            scrolledUnderElevation: 9999,
            floating: true,
            snap: true,
          ),
        ],
        body: RefreshIndicator(
          onRefresh: () async {
            if (cycle.isLastCycle) {
              context
                  .read<WishlistProvider>()
                  .fetchWishlist(context, refresh: true);
            }
          },
          child: Center(
            child: FutureBuilder(
              future: context.watch<WishlistProvider>().getWishlist(context),
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
                      'No wishlist found.',
                      textAlign: TextAlign.center,
                    ),
                  ); //* Display a message for no wishlist
                } else {
                  //* Display the list of wishlist
                  final wishlist = snapshot.data!;

                  return ListView.builder(
                    itemCount: wishlist.length,
                    itemBuilder: (context, index) {
                      Wishlist wish = wishlist[index] as Wishlist;

                      return Column(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Card(
                              child: ListTile(
                                title: Text(wish.name),
                                onTap: () =>
                                    wish.showWishlistDetails(context, cycle),
                              ),
                            ),
                          ),
                          if (!context.read<PersonProvider>().user!.isPremium &&
                              (index == 1 || index == 7 || index == 13))
                            AdContainer(
                              adCacheService: _adCacheService,
                              number: index,
                              adSize: AdSize.banner,
                              adUnitId: _adMobService.bannerWishlistAdUnitId!,
                              height: 50.0,
                            ),
                          if (index == wishlist.length - 1)
                            const SizedBox(height: 80),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Wishlist.showWishlistFormDialog(context, 'Add');
        },
        child: const Icon(CupertinoIcons.add),
      ),
    );
  }
}
