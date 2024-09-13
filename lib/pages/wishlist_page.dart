// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/ad_mob_service.dart';
import '../size_config.dart';
import '../widgets/wishlist_dialog.dart';
import '../widgets/custom_draggable_scrollable_sheet.dart';
import '../extensions/firestore_extensions.dart';

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
    _fetchWishlist();
  }

  Future<void> _fetchWishlist() async {
    setState(() {
      wishlist = [];
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      //todo: Handle the case where user is not authenticated
      return;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final wishlistRef = userRef.collection('wishlist');

    final wishlistSnapshot =
        await wishlistRef.where('deleted_at', isNull: true).getSavy();

    final fetchedWishlist = wishlistSnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'name': doc['name'] as String,
              'note': doc['note'] as String,
              'created_at': (doc['created_at'] as Timestamp).toDate()
            })
        .toList();

    //* Sort the list by alphabetical in ascending order (most recent first)
    fetchedWishlist
        .sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    setState(() {
      wishlist = List.from(fetchedWishlist);

      final adMobService = context.read<AdMobService>();

      if (adMobService.status) {
        adMobService.initialization.then((value) {
          for (var i = 2; i < wishlist.length; i += 7) {
            wishlist.insert(
                i,
                BannerAd(
                  size: AdSize.banner,
                  adUnitId: adMobService.bannerWishlistAdUnitId!,
                  listener: adMobService.bannerAdListener,
                  request: const AdRequest(),
                )..load());
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        body: ListView.builder(
          itemCount: wishlist.length,
          itemBuilder: (context, index) {
            if (wishlist[index] is BannerAd) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 5.0),
                height: 50.0,
                child: AdWidget(ad: wishlist[index] as BannerAd),
              );
            } else {
              Map wish = wishlist[index] as Map;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                margin: index == wishlist.length - 1
                    ? const EdgeInsets.only(bottom: 80)
                    : null,
                child: Card(
                  child: ListTile(
                    title: Text(wish['name']),
                    onTap: () => showWishlistDetails(wish),
                  ),
                ),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showWishlistFormDialog(context, 'Add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  //* Function to show the add category dialog
  Future<bool> _showWishlistFormDialog(BuildContext context, String action,
      {Map? wish}) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return WishlistDialog(
          action: action,
          wish: wish ?? {},
          onWishlistChanged: _fetchWishlist,
        );
      },
    );
  }

  void showWishlistDetails(Map wish) {
    final String name = wish['name'];
    final String note = wish['note'];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return CustomDraggableScrollableSheet(
          initialSize: 0.45,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Category Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      final result = await _deleteHandler(wish['id']);

                      if (result) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final result = await _showWishlistFormDialog(
                          context, 'Edit',
                          wish: wish);

                      if (result) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          contents: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Name:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(name),
                ],
              ),
              if (note.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Note:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: SizeConfig.screenHeight! * 0.32,
                      ),
                      child: SingleChildScrollView(
                        child: MarkdownBody(
                          selectable: true,
                          data: note.replaceAll('\n', '  \n'),
                          onTapLink: (text, url, title) {
                            launchUrl(Uri.parse(url!));
                          },
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _deleteHandler(String id) async {
    //* Handle delete option
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this wish?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); //* Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                //* Delete the item from Firestore here
                final wishId = id;

                //* Reference to the Firestore document to delete
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  //todo: Handle the case where the user is not authenticated
                  return;
                }

                final userRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid);
                final wishlistRef = userRef.collection('wishlist');
                final wishRef = wishlistRef.doc(wishId);

                //* Update the 'deleted_at' field with the current timestamp
                final now = DateTime.now();
                wishRef.update({
                  'updated_at': now,
                  'deleted_at': now,
                });

                _fetchWishlist();

                Navigator.of(context).pop(true); //* Close the dialog
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
