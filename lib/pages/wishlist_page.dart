// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../models/cycle.dart';
import '../models/wishlist.dart';
import '../providers/cycle_provider.dart';
import '../providers/wishlist_provider.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<Object> wishlist = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (context.read<WishlistProvider>().wishlist == null) {
      context.read<WishlistProvider>().fetchWishlist(context);
    }
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
                    if (wishlist[index] is BannerAd) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 5.0),
                        height: 50.0,
                        child: AdWidget(ad: wishlist[index] as BannerAd),
                      );
                    } else {
                      Wishlist wish = wishlist[index] as Wishlist;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        margin: index == wishlist.length - 1
                            ? const EdgeInsets.only(bottom: 80)
                            : null,
                        child: Card(
                          child: ListTile(
                            title: Text(wish.name),
                            onTap: () =>
                                wish.showWishlistDetails(context, cycle),
                          ),
                        ),
                      );
                    }
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
