import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cycle.dart';
import '../models/wishlist.dart';
import '../pages/wishlist_page.dart';
import '../providers/cycle_provider.dart';
import '../providers/wishlist_provider.dart';

class PinnedWishlist extends StatefulWidget {
  const PinnedWishlist({super.key});

  @override
  State<PinnedWishlist> createState() => _PinnedWishlistState();
}

class _PinnedWishlistState extends State<PinnedWishlist> {
  bool showPinnedWishlist = false;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future<void> initAsync() async {
    SharedPreferences? sharedPreferences =
        await SharedPreferences.getInstance();
    final savedShowPinnedWishlist =
        sharedPreferences.getBool('show_pinned_wishlist');

    setState(() {
      showPinnedWishlist = savedShowPinnedWishlist ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Cycle? cycle = context.watch<CycleProvider>().cycle;

    return showPinnedWishlist
        ? Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pinned Wishlist',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WishlistPage(),
                            ),
                          );
                        },
                        child: const Text('See all'))
                  ],
                ),
              ),
              FutureBuilder(
                future: context
                    .watch<WishlistProvider>()
                    .getPinnedWishlist(context),
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
                        'No pinned wishlist found.',
                        textAlign: TextAlign.center,
                      ),
                    ); //* Display a message for no wishlist
                  } else {
                    //* Display the list of wishlist
                    final wishlist = snapshot.data!;
                    return Column(
                      children: wishlist.asMap().entries.map<Widget>((entry) {
                        Wishlist wish = entry.value as Wishlist;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Card(
                            child: ListTile(
                              title: Text(wish.name),
                              onTap: () =>
                                  wish.showWishlistDetails(context, cycle),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          )
        : Container();
  }
}
