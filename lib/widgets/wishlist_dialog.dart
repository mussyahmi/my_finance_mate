// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/wishlist.dart';
import '../providers/wishlist_provider.dart';

class WishlistDialog extends StatefulWidget {
  final String action;
  final Wishlist? wish;

  const WishlistDialog({
    Key? key,
    required this.action,
    required this.wish,
  }) : super(key: key);

  @override
  WishlistDialogState createState() => WishlistDialogState();
}

class WishlistDialogState extends State<WishlistDialog> {
  final TextEditingController _wishlistNameController = TextEditingController();
  final TextEditingController _wishlistNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.wish != null) {
      _wishlistNameController.text = widget.wish!.name;
      _wishlistNoteController.text = widget.wish!.note;
    }
  }

  @override
  void dispose() {
    _wishlistNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: AlertDialog(
        title: Text('${widget.action} Wishlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _wishlistNameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _wishlistNoteController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); //* Close the dialog
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              FocusManager.instance.primaryFocus?.unfocus();

              final wishlistName = _wishlistNameController.text;
              final wishlistNote = _wishlistNoteController.text;

              final message = _validate(wishlistName);

              if (message.isNotEmpty) {
                final snackBar = SnackBar(
                  content: Text(
                    message,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.onError),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  showCloseIcon: true,
                  closeIconColor: Theme.of(context).colorScheme.onError,
                );

                ScaffoldMessenger.of(context).showSnackBar(snackBar);

                return;
              }

              await context.read<WishlistProvider>().updateWishlist(
                    context,
                    widget.action,
                    wishlistName,
                    wishlistNote,
                    wish: widget.wish,
                  );

              //* Close the dialog
              Navigator.of(context).pop(true);
            },
            child: Text(widget.action == 'Edit' ? 'Save' : widget.action),
          ),
        ],
      ),
    );
  }

  String _validate(String name) {
    if (name.isEmpty) {
      return 'Please enter wishlist\'s name.';
    }

    return '';
  }
}
