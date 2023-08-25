import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistDialog extends StatefulWidget {
  final String action;
  final Map wish;
  final void Function() onWishlistChanged;

  const WishlistDialog(
      {Key? key,
      required this.action,
      required this.wish,
      required this.onWishlistChanged})
      : super(key: key);

  @override
  WishlistDialogState createState() => WishlistDialogState();
}

class WishlistDialogState extends State<WishlistDialog> {
  final TextEditingController _wishlistNameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.wish.isNotEmpty) {
      _wishlistNameController.text = widget.wish['name'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.action} Wishlist'),
      content: TextField(
        controller: _wishlistNameController,
        decoration: const InputDecoration(
          labelText: 'Name',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); //* Close the dialog
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final wishlistName = _wishlistNameController.text;
            if (wishlistName.isNotEmpty) {
              //* Call the function to update to Firebase
              updateWishlistToFirebase(wishlistName);

              //* Close the dialog
              Navigator.of(context).pop();
            }
          },
          child: Text(widget.action),
        ),
      ],
    );
  }

  //* Function to update wishlist to Firebase Firestore
  Future<void> updateWishlistToFirebase(String wishlistName) async {
    try {
      //* Get current timestamp
      final now = DateTime.now();

      //* Get the current user
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        //todo: Handle the case where user is not authenticated
        return;
      }

      if (widget.action == 'Add') {
        //* Create the new cycle document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('wishlist')
            .add({
          'name': wishlistName,
          'created_at': now,
          'updated_at': now,
          'deleted_at': null,
          'version_json': null,
        });
      } else if (widget.action == 'Edit') {
        final docId =
            widget.wish['id']; //* Get the ID of the wishlist item to edit
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('wishlist')
            .doc(docId)
            .update({
          'name': wishlistName,
          'updated_at': now,
        });
      }

      //* Notify the parent widget about the wishlist addition
      widget.onWishlistChanged();
    } catch (e) {
      //* Handle any errors that occur during the Firebase operation
      // ignore: avoid_print
      print('Error updating wishlist: $e');
    }
  }

  @override
  void dispose() {
    _wishlistNameController.dispose();
    super.dispose();
  }
}
