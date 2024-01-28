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
        await wishlistRef.where('deleted_at', isNull: true).get();

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        centerTitle: true,
      ),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
              margin: index == wishlist.length - 1
                  ? const EdgeInsets.only(bottom: 80)
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ListTile(
                  title: Text(wish['name']),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz),
                    onSelected: (value) {
                      if (value == 'edit') {
                        //* Handle edit option
                        _showWishlistDialog(context, 'Edit', wish: wish);
                      } else if (value == 'delete') {
                        //* Handle delete option
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: const Text(
                                  'Are you sure you want to delete this wish?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); //* Close the dialog
                                  },
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    //* Delete the item from Firestore here
                                    final wishId = wish['id'];

                                    //* Reference to the Firestore document to delete
                                    final user =
                                        FirebaseAuth.instance.currentUser;
                                    if (user == null) {
                                      //todo: Handle the case where the user is not authenticated
                                      return;
                                    }

                                    final userRef = FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid);
                                    final wishlistRef =
                                        userRef.collection('wishlist');
                                    final wishRef = wishlistRef.doc(wishId);

                                    //* Update the 'deleted_at' field with the current timestamp
                                    final now = DateTime.now();
                                    wishRef.update({
                                      'updated_at': now,
                                      'deleted_at': now,
                                    });

                                    _fetchWishlist();

                                    Navigator.of(context)
                                        .pop(); //* Close the dialog
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          title: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    showWishlistSummaryDialog(wish['name'], wish['note']);
                  },
                ),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showWishlistDialog(context, 'Add');
        },
        icon: const Icon(Icons.add),
        label: const Text('Wishlist'),
      ),
    );
  }

  //* Function to show the add category dialog
  void _showWishlistDialog(BuildContext context, String action, {Map? wish}) {
    showDialog(
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

  void showWishlistSummaryDialog(String name, String note) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Wishlist Summary'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        maxHeight: SizeConfig.screenHeight! * 0.2,
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
              //* Add more wishlist details as needed
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); //* Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
