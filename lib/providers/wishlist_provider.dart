// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../extensions/firestore_extensions.dart';
import '../models/person.dart';
import '../models/wishlist.dart';
import 'user_provider.dart';

class WishlistProvider extends ChangeNotifier {
  List<Wishlist>? wishlist;

  WishlistProvider({this.wishlist});

  Future<void> fetchWishlist(BuildContext context, {bool? refresh}) async {
    final Person user = context.read<UserProvider>().user!;

    final wishlistSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .where('deleted_at', isNull: true)
        .orderBy('name')
        .getSavy(refresh: refresh);
    print('fetchWishlist: ${wishlistSnapshot.docs.length}');

    wishlist = wishlistSnapshot.docs.map((doc) {
      return Wishlist(
        id: doc.id,
        name: doc['name'],
        note: doc['note'],
        createdAt: (doc['created_at'] as Timestamp).toDate(),
      );
    }).toList();

    notifyListeners();
  }

  Future<List<Object>> getWishlist(BuildContext context) async {
    if (wishlist == null) return [];

    return wishlist!;
  }

  Future<void> updateWishlist(BuildContext context, String action,
      String wishlistName, String wishlistNote,
      {Wishlist? wish}) async {
    try {
      final Person user = context.read<UserProvider>().user!;

      //* Get current timestamp
      final now = DateTime.now();

      if (action == 'Add') {
        //* Create the new wish document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('wishlist')
            .add({
          'name': wishlistName,
          'note': wishlistNote,
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
        });
      } else if (action == 'Edit') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('wishlist')
            .doc(wish!.id)
            .update({
          'name': wishlistName,
          'note': wishlistNote,
          'updated_at': now,
        });
      }

      await context.read<WishlistProvider>().fetchWishlist(context);
    } catch (e) {
      //* Handle any errors that occur during the Firebase operation
      print('Error $action wishlist: $e');
    }
  }

  Future<void> deleteWish(BuildContext context, String wishId) async {
    final Person user = context.read<UserProvider>().user!;

    //* Update the 'deleted_at' field with the current timestamp
    final now = DateTime.now();
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(wishId)
        .update({
      'updated_at': now,
      'deleted_at': now,
    });

    wishlist!.removeWhere((wish) => wish.id == wishId);
    notifyListeners();
  }
}
